require 'rails_helper'

describe RewardExpiryJob do
  let!(:variant) { ShopifyAPI::Variant.new(id: '0', product_id: '0', inventory_quantity: 1) }
  let!(:reward) { create :reward, redeemed_remote_variant_id: variant.id }

  before do
    allow(ShopifyAPI::Variant).to receive(:find).and_return(variant)
    allow_any_instance_of(RewardRemoverJob).to receive(:perform)
  end

  describe '#perform' do
    it 'calls the RewardRemoverJob' do
      expect_any_instance_of(RewardRemoverJob).to receive(:perform).with(reward.customer.shop_id, reward.customer.remote_id, '0', '0')

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
      before { variant.inventory_quantity = 0 }

      it 'does nothing' do
        expect_any_instance_of(RewardRemoverJob).not_to receive(:perform)

        RewardExpiryJob.perform_later(reward.id)
      end
    end
  end
end
