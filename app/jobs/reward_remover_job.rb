class RewardRemoverJob < ApplicationJob
  attr_reader :remote_variant, :variant, :customer

  queue_as :reward_sync

  def perform(variant_id, customer_id)
    @variant        = ProductVariant.find_by(remote_id: variant_id)
    @remote_product = ShopifyAPI::Product.find(variant.product.remote_id)
    @customer       = Customer.find_by(remote_id: customer_id)

    remove!
  rescue ActiveResource::ResourceNotFound => e
  end

  private

  def remove!
    # referenced variant_id?
    # increase the quantity of referenced variant
    remote_variant.destroy!

    loyalty_lion.add(points: variant.product.points_cost, product_name: variant.product.title)
  end

  def loyalty_lion
    @loyalty_lion ||= LoyaltyLion.new(customer)
  end
end
