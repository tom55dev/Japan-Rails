class LoyaltyLion
  attr_reader :shop, :customer

  def initialize(shop, customer)
    @shop = shop
    @customer = customer
  end

  def add(points:, product_name:)
    shop.with_shopify_session do
      post_to_loyalty_lion('points', points, product_name)
    end
  end

  def deduct(points:, product_name:)
    shop.with_shopify_session do
      if points_approved >= points
        post_to_loyalty_lion('remove_points', points, product_name)
      else
        { success: false, error: cannot_claim_reward_message }
      end
    end
  end

  private

  def post_to_loyalty_lion(type, points, product_name)
    RestClient.post(api_url + '/' + type, { points: points, reason: product_name }.to_json, { accept: 'json', content_type: 'json' }) do |response|
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
  end

  def points_approved
    remote_customer = ShopifyAPI::Customer.find(customer.remote_id)
    metafield = remote_customer.metafields.find { |m| m.namespace == 'loyaltylion' && m.key == 'points_approved' }

    metafield&.value || 0
  end

  def cannot_claim_reward_message
    'Sorry, you don\'t have enough points to claim this reward.'
  end
end
