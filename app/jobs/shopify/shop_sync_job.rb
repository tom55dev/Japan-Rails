class Shopify::ShopSyncJob < ApplicationJob
  queue_as :shopify_sync

  def perform(args = {})
    shop = Shop.find_by(shopify_domain: args[:shop_domain])

    SyncAllProducts.new(shop).call
  end
end
