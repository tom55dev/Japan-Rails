class LoyaltyLion::PointsUpdateJob < ApplicationJob
  queue_as :shopify_sync

  def perform(args)
    shop = Shop.find_by(shopify_domain: args[:shop])
    customer = CustomerFinder.new(shop, args[:customer_id]).call

    customer.update!(points_approved: args[:points_approved])
  end
end
