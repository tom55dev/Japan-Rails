class LoyaltyLion
  class CannotFetchPointsError < StandardError; end

  attr_reader :customer

  def initialize(customer)
    @customer = customer
  end

  def points_approved
    if customer.points_approved.blank?
      customer.update!(points_approved: fetch_points_approved)
    end

    customer.points_approved || 0
  end

  def add(points:, product_name:)
    post_to_loyalty_lion('points', points, "Reward removed from cart: #{product_name}") do
      update_customer_points(points)
    end
  end

  def deduct(points:, product_name:)
    if points_approved >= points
      post_to_loyalty_lion('remove_points', points, "Reward redeemed: #{product_name}") do
        update_customer_points(-points)
      end
    else
      { success: false, error: cannot_claim_reward_message }
    end
  end

  private

  def post_to_loyalty_lion(type, points, reason)
    RestClient.post(customer_api_url + '/' + type, { points: points, reason: reason }.to_json, { accept: 'json', content_type: 'json' }) do |response|
      success = response.code.between?(200, 209)

      yield if success

      { success: success, error: error_msg(response) }
    end
  end

  def update_customer_points(amount)
    # LoyaltyLion's webhook will update these if this fails for some reason
    # We don't want to raise an error here and end up retrying and redoing the LoyaltyLion request
    customer.update(points_approved: customer.points_approved + amount) if customer.points_approved.present?
  end

  def fetch_points_approved
    RestClient.get(base_api_url + '/v2/customers', headers: { params: { email: customer.email } }) do |response|
      if response.code.between?(200, 209)
        find_customer_points(JSON.parse(response.body)['customers'])
      else
        raise CannotFetchPointsError, "Got a #{response.code} response: #{response.body}"
      end
    end
  end

  def find_customer_points(customers)
    customer_data = customers.find { |data| data['merchant_id'].to_s == customer.remote_id }

    raise CannotFetchPointsError, "Could not find #{customer.remote_id} in response for #{customer.email}" unless customer_data.present?

    customer_data['points_approved']
  end

  def credentials
    [
      Rails.application.secrets.loyalty_lion_api_token,
      Rails.application.secrets.loyalty_lion_api_secret
    ].join(':')
  end

  def customer_api_url
    "#{base_api_url}/v2/customers/#{customer.remote_id}"
  end

  def base_api_url
    "https://#{credentials}@#{Rails.application.secrets.loyalty_lion_api_url}"
  end

  def error_msg(response)
    json = JSON.parse(response.body, symbolize_names: true)

    if json[:error].to_s.include?('Customer does not have enough points')
      cannot_claim_reward_message
    else
      json[:error]
    end
  rescue JSON::ParserError => e
  end

  def cannot_claim_reward_message
    'Sorry, you don\'t have enough points to claim this reward.'
  end
end
