class LoyaltyLion
  attr_reader :customer

  def initialize(customer)
    @customer = customer
  end

  def points_approved
    @points_approved ||= ShopifyAPI::Metafield.where(
      resource: 'customers',
      resource_id: customer.remote_id,
      namespace: 'loyaltylion',
      key: 'points_approved'
    ).first&.value || 0
  end

  def add(points:, product_name:)
    post_to_loyalty_lion('points', points, "Reward removed from cart: #{product_name}")
  end

  def deduct(points:, product_name:)
    if points_approved >= points
      post_to_loyalty_lion('remove_points', points, "Reward redeemed: #{product_name}")
    else
      { success: false, error: cannot_claim_reward_message }
    end
  end

  private

  def post_to_loyalty_lion(type, points, reason)
    RestClient.post(api_url + '/' + type, { points: points, reason: reason }.to_json, { accept: 'json', content_type: 'json' }) do |response|
      { success: response.code.between?(200, 209), error: error_msg(response) }
    end
  end

  def credentials
    [
      Rails.application.secrets.loyalty_lion_api_token,
      Rails.application.secrets.loyalty_lion_api_secret
    ].join(':')
  end

  def api_url
    "https://#{credentials}@#{Rails.application.secrets.loyalty_lion_api_url}/v2/customers/#{customer.remote_id}"
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
