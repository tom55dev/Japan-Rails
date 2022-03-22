class Shopify::RefundsCreateJob < ApplicationJob
  REWARD_PREFIX = 'Reward #'
  class CannotRefundError < StandardError; end

  queue_as :reward_sync

  def perform(args = {})
    shop = Shop.find_by(shopify_domain: args[:shop_domain])

    access = ShopifyAPI::Session.new(domain: shop.shopify_domain, token: shop.shopify_token, api_version: ShopifyApp.configuration.api_version)

    ShopifyAPI::Base.activate_session(access)

    remote = ShopifyAPI::Refund.new(args[:webhook])

    reward_variant_ids = remote.refund_line_items.map do |refund_line_item|
      line_item = refund_line_item.line_item
      line_item.variant_id if line_item.variant_title.to_s.include?(REWARD_PREFIX)
    end.compact

    refund!(reward_variant_ids) if reward_variant_ids.any?
  end

  private

  def refund!(reward_variant_ids)
    Reward.where(redeemed_remote_variant_id: reward_variant_ids).each do |reward|
      next if reward.refunded_at?
      result = refund_points!(reward)

      if result[:success]
        reward.update!(refunded_at: Time.zone.now)
      else
        raise CannotRefundError.new(result[:error])
      end
    end
  end

  def refund_points!(reward)
    product = reward.product_variant.product

    lion = LoyaltyLion.new(reward.customer)

    lion.add(points: product.points_cost, product_name: reward.product_variant.product.title, action: 'refunded')
  end
end
