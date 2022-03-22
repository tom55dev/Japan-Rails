require 'rails_helper'

describe RewardExpiryJob do
  let!(:shop) { create :shop }
  let!(:variant) { ShopifyAPI::Variant.new(id: '0', product_id: '0', inventory_item_id: '0') }
  let!(:inventory_level) { ShopifyAPI::InventoryLevel.new(inventory_item_id: '0', available: 1) }
  let!(:reward) { create :reward, redeemed_remote_variant_id: variant.id }

  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(domain: shop.shopify_domain, token: shop.shopify_token, api_version: ShopifyApp.configuration.api_version))

    allow(ShopifyAPI::Variant).to receive(:find).and_return(variant)
    allow(ShopifyAPI::InventoryLevel).to receive(:find).and_return([inventory_level])
    allow_any_instance_of(RewardRemoverJob).to receive(:perform)
  end

  describe '#perform' do
    it 'calls the RewardRemoverJob' do
      expect_any_instance_of(RewardRemoverJob).to receive(:perform).with(shop_id: reward.customer.shop_id, customer_id: reward.customer.remote_id, variant_id: '0', product_id: '0')

      RewardExpiryJob.perform_later(reward.id)
    end

    context 'when reward has been purchased' do
      before { reward.update!(purchased_at: Time.zone.now) }

      it 'does nothing' do
        expect_any_instance_of(RewardRemoverJob).not_to receive(:perform)

        RewardExpiryJob.perform_later(reward.id)
      end
    end

    context 'when quantity of variant is zero' do
      before { inventory_level.available = 0 }

      it 'does nothing' do
        expect_any_instance_of(RewardRemoverJob).not_to receive(:perform)

        RewardExpiryJob.perform_later(reward.id)
      end
    end
  end
end
