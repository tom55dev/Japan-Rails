class Shopify::ProductsUpdateJob < ApplicationJob
  queue_as :shopify_sync

  def perform(args = {})
    shop = Shop.find_by(shopify_domain: args[:shop_domain])

    access = ShopifyAPI::Session.new(domain: shop.shopify_domain, token: shop.shopify_token, api_version: ShopifyApp.configuration.api_version)

    ShopifyAPI::Base.activate_session(access)

    remote_product = ShopifyAPI::Product.new(args[:webhook])
    product = ProductSync.new(shop, remote_product).call

    product.product_variants.where.not(remote_id: remote_product.variants.map(&:id)).destroy_all
    remote_product.variants.each do |remote_variant|
      ProductVariantSync.new(product, remote_variant).call
    end
  end
end
