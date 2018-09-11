class RewardExpiryJob < ApplicationJob
  queue_as :reward_sync

  def perform(reward_id)
    reward = Reward.find(reward_id)
    return if reward.purchased_at.present? # Don't expire if customer has successfully checkout

    variant = ShopifyAPI::Variant.find(reward.redeemed_remote_variant_id)

    return if variant.inventory_quantity.zero? # Double check if variant was actually used in an order and skip this job

    RewardRemoverJob.new.perform(reward.customer.remote_id, variant.product_id, variant.id)
  rescue ActiveRecord::RecordNotFound, ActiveResource::ResourceNotFound => e
  end
end
