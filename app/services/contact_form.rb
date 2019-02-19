class ContactForm
  MAX_ATTACHMENTS = 5
  MAX_TOTAL_ATTACHED_MB = 25

  include ActiveModel::Model

  # ID => Zendesk field value ("tag name")
  BRANDS = {
    tokyotreat: 'tt',
    yumetwins: 'yt',
    nomakenolife: 'nmnl'
  }

  PURPOSES = ['Shipping', 'Product', 'Reward Haul']

  ATTRIBUTES = [:purpose, :first_name, :last_name, :email, :subject, :message, attachments: []]

  attr_accessor :purpose, :first_name, :last_name, :email, :subject, :message, :attachments

  validates :email, email: true
  validates :first_name, :last_name, :subject, :message, presence: true
  validate :attachment_quantity_and_size
  validates :purpose, inclusion: { in: PURPOSES }

  def zendesk_category_id
    'support'
  end

  def save
    return false unless valid?

    response = RestClient.post(
      "#{api_base_url}/requests.json",
      create_request_params.to_json,
      content_type: :json,
      accept: :json
    )
    return false unless response.code.between?(200, 209)

    add_extra_info(JSON.parse(response.body)['request']['id'])

    true
  rescue RestClient::ExceptionWithResponse => e
    raise if Rails.env.development?
    Appsignal.set_error(e)

    errors.add(:base, 'Sorry, your request could not be submitted. Please try again later.')
    false
  end

  def help_center(url: '/help_center/en-us/articles.json')
    response = RestClient.get(
      "#{api_base_url}#{url}",
      accept: :json
    )
    JSON.parse(response.body)
  end

  private

  def api_base_url
    "#{Rails.application.secrets.zendesk_url}/api/v2"
  end

  def api_authorization
    auth = "#{Rails.application.secrets.zendesk_email}/token:#{Rails.application.secrets.zendesk_token}"
    "Basic #{Base64.urlsafe_encode64(auth)}"
  end

  def create_request_params
    {
      request: {
        requester: { name: [first_name, last_name].join(' '), email: email },
        subject: formatted_subject,
        comment: { body: message },

        # Note: These custom fields on Zendesk must be editable by the customer, otherwise this anonymous API will silently ignore them
        custom_fields: zendesk_custom_field_params({
          purpose: purpose
        })
      }
    }
  end

  def zendesk_custom_field_params(custom_fields)
    custom_fields.map do |id, value|
      { id: custom_field_ids[id], value: value }
    end
  end

  def formatted_subject
    "[#{zendesk_brand_id.upcase}][#{zendesk_category_id.titleize}] #{subject}"
  end

  def add_extra_info(ticket_id)
    # add_additional_tags(ticket_id)
    add_attachments(ticket_id)
  rescue RestClient::ExceptionWithResponse => e
    raise if Rails.env.development?
    # Better to tell the user the ticket was created and let support request the attachments
    # separately than raise an error and end up with users spamming heaps of tickets
    Appsignal.set_error(e)
  end

  def add_attachments(ticket_id)
    return unless attachments.present?

    tokens = attachments.map { |attachment| upload_attachment(attachment) }.compact
    add_attachments_to_ticket(ticket_id, tokens)
  end

  def upload_attachment(attachment)
    response = RestClient.post(
      "#{api_base_url}/uploads.json?filename=#{URI.encode(attachment.original_filename)}",
      attachment.tempfile,
      content_type: attachment.content_type,
      accept: :json,
      'Authorization' => api_authorization
    )

    JSON.parse(response.body)['upload']['token'] if response.code.between?(200, 209)
  end

  def add_attachments_to_ticket(ticket_id, tokens)
    RestClient.put(
      "#{api_base_url}/tickets/#{ticket_id}.json",
      {
        ticket: { comment: { body: 'User uploaded attachments', uploads: tokens, public: false } }
      }.to_json,
      content_type: :json,
      accept: :json,
      'Authorization' => api_authorization
    )
  end

  def attachment_quantity_and_size
    return unless attachments.present?

    # Add error to :base because there's no visible error on attachments on the form
    if attachments.size > MAX_ATTACHMENTS
      errors.add(:base, "Sorry, you can't upload more than #{MAX_ATTACHMENTS} attachments using this form. Please add any additional files by email after submitting your request.")
    elsif attachments.sum(&:size) > (MAX_TOTAL_ATTACHED_MB * 1000000)
      errors.add(:base, "Sorry, you can't upload more than #{MAX_TOTAL_ATTACHED_MB}MB of attachments using this form. Please add any additional files by email after submitting your request.")
    end
  end

  def zendesk_brand_id
    'JapanHaul'
  end

  def custom_field_ids
    Rails.application.secrets.zendesk_custom_field_ids
  end
end
