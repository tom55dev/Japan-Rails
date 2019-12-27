class Shopify::OrdersPaidJob < ApplicationJob
  queue_as :shopify_sync

  def perform(args = {})
    shop = Shop.find_by(shopify_domain: args[:shop_domain])

    shop.with_shopify_session do
      order = ShopifyAPI::Order.new(args[:webhook])

      variant_ids = order.line_items.map(&:variant_id).compact

      Reward.where(redeemed_remote_variant_id: variant_ids).each do |reward|
        reward.update(purchased_at: paid_at(order))
        remove_reward_variant!(reward.redeemed_remote_variant_id)
      end
    end
  end

  private

  def remove_reward_variant!(reward_variant_id)
    variant = ShopifyAPI::Variant.find(reward_variant_id)
    variant.destroy
  rescue ActiveResource::ResourceNotFound => e
    # Handles 404 to proceed
  end

  def paid_at(order)
    @paid_at ||= paid_at_by_transaction(order) || order.created_at
  end

  def paid_at_by_transaction(order)
    order.transactions.find { |t| t.kind == 'sale' && t.status == 'success' }&.created_at
  end
end
