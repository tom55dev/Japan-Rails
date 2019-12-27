namespace :tmp_delete_old_purchased_rewards do
  task update_all: :environment do
    Reward.where.not(purchased_at: nil).includes(customer: :shop).find_each do |reward|
      reward.customer.shop.with_shopify_session do
        begin
          variant = ShopifyAPI::Variant.find(reward.redeemed_remote_variant_id)
          variant.destroy

          puts "Deleted variant #{reward.redeemed_remote_variant_id}"

          sleep 1
        rescue ActiveResource::ResourceNotFound => e
          puts "Variant #{reward.redeemed_remote_variant_id} is already deleted"
        end
      end
    end
  end
end
