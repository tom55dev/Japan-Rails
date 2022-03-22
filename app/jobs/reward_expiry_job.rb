class RewardExpiryJob < ApplicationJob
  queue_as :reward_sync

  def perform(reward_id)
    reward = Reward.find(reward_id)
    return if reward.purchased_at.present? # Don't expire if customer has successfully checkout

    reward.customer.shop.with_shopify_session do
      variant = ShopifyAPI::Variant.find(reward.redeemed_remote_variant_id)
      inventory_level = ShopifyAPI::InventoryLevel.where(inventory_item_ids: variant.inventory_item_id).first

      # Double check if variant was actually used in an order and skip this job
      return if inventory_level.blank? || inventory_level.available.blank? || inventory_level.available.zero?

      RewardRemoverJob.new.perform(
        shop_id: reward.customer.shop_id,
        customer_id: reward.customer.remote_id,
        product_id: variant.product_id,
        variant_id: variant.id
      )
    end
  rescue ActiveRecord::RecordNotFound, ActiveResource::ResourceNotFound => e
  end
end
