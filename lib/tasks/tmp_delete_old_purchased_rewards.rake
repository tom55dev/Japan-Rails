namespace :tmp_delete_old_purchased_rewards do
  task update_all: :environment do
    variant_ids = Reward.where.not(purchased_at: nil).pluck(:redeemed_remote_variant_id)

    variant_ids.each do |variant_id|
      variant = ShopifyAPI::Variant.find(variant_id)
      variant.destroy

      puts "Deleted variant #{variant_id}"

      sleep 1
    end
  end
end
