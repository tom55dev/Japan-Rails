class RewardRestorerJob < ApplicationJob
  def perform(shop_id:, remote_variant_id:, reward_variant_id:, remote_variant_deducted:)
    Shop.find(shop_id).with_shopify_session do
      remove_reward_variant!(reward_variant_id)

      adjust_remote_variant!(remote_variant_id) if remote_variant_deducted
    end
  end

  def remove_reward_variant!(reward_variant_id)
    variant = ShopifyAPI::Variant.find(reward_variant_id)

    variant.destroy
  rescue ActiveResource::ResourceNotFound => e
    # Handles 404 to proceed
  end

  def adjust_remote_variant!(remote_variant_id)
    variant = ShopifyAPI::Variant.find(remote_variant_id)
    inventory_level = ShopifyAPI::InventoryLevel.where(inventory_item_ids: variant.inventory_item_id).first

    inventory_level.adjust(1)
  end
end
