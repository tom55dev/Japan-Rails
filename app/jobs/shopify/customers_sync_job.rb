class Shopify::CustomersSyncJob < ApplicationJob
  queue_as :shopify_sync

  def perform(args = {})
    shop = Shop.find_by(shopify_domain: args[:shop_domain])

    shop.with_shopify_session do
      customer = ShopifyAPI::Customer.new(args[:webhook])
      CustomerSync.new(shop, shopify_customer: customer).call
    end
  end
end
