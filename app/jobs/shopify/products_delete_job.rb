class Shopify::ProductsDeleteJob < ApplicationJob
  queue_as :shopify_sync

  def perform(args = {})
    shop = Shop.find_by(shopify_domain: args[:shop_domain])

    access = ShopifyAPI::Session.new(domain: shop.shopify_domain, token: shop.shopify_token, api_version: ShopifyApp.configuration.api_version)

    ShopifyAPI::Base.activate_session(access)

    product = shop.products.where(remote_id: args[:webhook][:id]).first

    product.destroy if product.present?
  end
end
