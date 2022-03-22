class Shopify::ProductsCreateJob < ApplicationJob
  queue_as :shopify_sync

  def perform(args = {})
    shop = Shop.find_by(shopify_domain: args[:shop_domain])

    access = ShopifyAPI::Session.new(domain: shop.shopify_domain, token: shop.shopify_token, api_version: ShopifyApp.configuration.api_version)

    ShopifyAPI::Base.activate_session(access)

    shopify_product = ShopifyAPI::Product.new(args[:webhook])
    model = ProductSync.new(shop, shopify_product).call

    shopify_product.variants.each do |variant|
      ProductVariantSync.new(model, variant).call
    end
  end
end
