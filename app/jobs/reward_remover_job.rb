class RewardRemoverJob < ApplicationJob
  attr_reader :reward, :remote_product, :customer, :add_points

  queue_as :reward_sync

  def perform(customer_id, product_id, variant_id, add_points=true)
    @customer = Customer.find_by(remote_id: customer_id)
    @reward   = customer.rewards.find_by(redeemed_remote_variant_id: variant_id)
    @add_points = true

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
    @variant ||= ProductVariant.find_by(remote_id: referenced_variant.id)
  end

  def remove!
    referenced_variant.inventory_quantity += 1 if redeemed_variant.present?
    remote_product.variants.reject! { |v| v == redeemed_variant }
    remote_product.save!

    loyalty_lion.add(points: variant.product.points_cost, product_name: variant.product.title) if add_points
    reward.destroy!
  end

  def loyalty_lion
    @loyalty_lion ||= LoyaltyLion.new(customer)
  end
end
