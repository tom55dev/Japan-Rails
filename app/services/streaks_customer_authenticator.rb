class StreaksCustomerAuthenticator
  attr_reader :shop, :customer_id, :user_uuid

  def initialize(shop, customer_id:, user_uuid:)
    @shop = shop
    @customer_id = customer_id
    @user_uuid = user_uuid
  end

  def call
    shop.with_shopify_session do
      user_uuid_matches? && active_streak_count.positive?
    end
  end

  private

  def user_uuid_matches?
    metafields['customer_portal.user_uuid'] == user_uuid
  end

  def active_streak_count
    metafields['customer_portal.active_streak_count'].to_i
  end

  def metafields
    @metafields ||= fetch_metafields.map do |metafield|
      [[metafield.namespace, metafield.key].join('.'), metafield.value]
    end.to_h
  end

  def fetch_metafields
    ShopifyAPI::Metafield.find(:all, params: { resource: 'customers', resource_id: customer_id }) || []
  end
end
