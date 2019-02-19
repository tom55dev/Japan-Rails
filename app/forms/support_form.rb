class Contact::SupportForm < Contact::BaseForm
  #TODO WW-408: Make tag naming consistent and equivalent to what support currently uses

  BILLING_PROBLEMS = {
    'Payment error'                     => { tag: 'payment-error' },
    'Payment is not taken'              => { tag: 'payment-error' },
    'Subscription renewal/cancellation' => { tag: 'cancellation' },
    'Others'                            => { tag: 'others' }
  }

  SHIPPING_PROBLEMS = {
    'Box is not arrived yet' => { partial: 'not_arrived',  tag: 'late' },
    'Missing item'           => { partial: 'missing_item', tag: 'damaged' },
    'Damaged item/box'       => { partial: 'damaged_item', tag: 'damaged' },
    'Others'                 => { partial: 'others',       tag: 'others' }
  }

  PURPOSES = {
    'Shipping' => {
      partial: 'shipping',
      value: 'shipment',
      additional_fields: [:account_email, :problem, :shipment_date, :received_date, :invoice_number, :box],
      problems: SHIPPING_PROBLEMS
    },
    'Subscription' => {
      partial: 'subscription',
      value: 'subscriptions',
      additional_tags: ['questions', 'accounts'],
      additional_fields: [:account_email]
    },
    'Billing & Payment' => {
      partial: 'billing',
      value: 'payment',
      additional_fields: [:account_email, :problem],
      problems: BILLING_PROBLEMS
    },
    # 'Account' => {
    #   partial: 'account',
    #   value: 'accounts',
    #   additional_tags: ['questions'],
    #   additional_fields: [:account_email]
    # },
    # 'Product' => {
    #   partial: 'product',
    #   value: 'products',
    #   additional_tags: ['questions']
    # },
    # 'Streaks' => {
    #   partial: 'streaks',
    #   value: 'streaks',
    #   additional_fields: [:account_email]
    # },
    # 'Affiliate Program' => {
    #   partial: 'affiliate',
    #   value: 'affiliate',
    #   additional_fields: [:website_url]
    # },
    # 'Refer-a-friend' => {
    #   partial: 'referral',
    #   value: 'referral'
    # },
    'JapanHaul Rewards' => {
      partial: 'rewards',
      value: 'rewardhaul'
    },
    'Website Problem' => {
      partial: 'website_problem',
      value: 'websiteproblem'
    }
  }

  ATTRIBUTES = Contact::BaseForm::ATTRIBUTES + [:purpose, :account_email, :problem, :shipment_date, :received_date, :invoice_number, :box, :website_url]

  attr_accessor :purpose, :account_email, :problem, :shipment_date, :received_date, :invoice_number, :box, :website_url

  validates :purpose, inclusion: { in: PURPOSES.keys }

  validates :account_email, email: true, if: -> { additional_fields.include?(:account_email) }
  validates :problem, inclusion: { in: ->(form) { form.possible_problems.keys } }, if: -> { additional_fields.include?(:problem) }
  validates :invoice_number, presence: true, if: -> { additional_fields.include?(:invoice_number) }
  validates :box, inclusion: { in: ->(form) { form.box_options } }, if: -> { additional_fields.include?(:box) }
  validates :website_url, url: true, if: -> { additional_fields.include?(:website_url) }

  def zendesk_category_id
    'support'
  end

  def zendesk_custom_fields
    { purpose: PURPOSES.dig(purpose, :value) }
  end

  def zendesk_body_fields
    additional_fields.map { |field| [field.to_s.titleize, send(field)] }.to_h
  end

  def zendesk_additional_tags
    tags = PURPOSES.dig(purpose, :additional_tags) || []
    tags << PURPOSES.dig(purpose, :problems, problem, :tag) if problem.present?
    tags
  end

  def possible_problems
    PURPOSES.dig(purpose, :problems) || {}
  end

  def box_options
    options = (0..5).map do |months_ago|
      box_date = months_ago.months.ago + 1.month
      box_date.strftime('%B %Y')
    end

    options + ['Other']
  end

  private

  def additional_fields
    PURPOSES.dig(purpose, :additional_fields) || []
  end
end
