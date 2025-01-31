class RewardRemoverJob < ApplicationJob
  attr_reader :shop, :reward, :remote_product, :customer, :add_points

  queue_as :reward_sync

  def perform(shop_id:, customer_id:, product_id:, variant_id:, add_points: true)
    @shop = Shop.find(shop_id)
    @customer = CustomerFinder.new(shop, customer_id).call
    @reward   = customer.rewards.find_by(redeemed_remote_variant_id: variant_id)
    @add_points = add_points

    return if reward.blank?

    customer.shop.with_shopify_session do
      @remote_product = ShopifyAPI::Product.find(product_id)
      remove!
    end
  end

  private

  def redeemed_variant
    remote_product.variants.find { |v| v.id.to_s == reward.redeemed_remote_variant_id }
  end

  def referenced_variant
    remote_product.variants.find { |v| v.id.to_s == reward.referenced_remote_variant_id }
  end

  def variant
    @variant ||= shop.product_variants.find_by(remote_id: referenced_variant.id)
  end

  def remove!
    RewardRestorerJob.perform_later(
      shop_id: shop.id,
      remote_variant_id: referenced_variant.id,
      reward_variant_id: redeemed_variant.id,
      remote_variant_deducted: true
    )

    loyalty_lion.add(points: variant.product.points_cost, product_name: variant.product.title) if add_points
    reward.destroy!
  end

  def loyalty_lion
    @loyalty_lion ||= LoyaltyLion.new(customer)
  end
end
