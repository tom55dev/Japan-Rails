require 'rails_helper'

describe Shopify::RefundsCreateJob do
  let!(:shop) { create :shop }
  let!(:customer) { create :customer, shop: shop }
  let!(:product) { create :product, shop: shop, points_cost: 500 }
  let!(:product_variant) { create :product_variant, product: product }
  let!(:reward) { create :reward, customer: customer, purchased_at: nil, redeemed_remote_variant_id: product_variant.remote_id }
  let!(:args) do
    {
      shop_domain: shop.shopify_domain,
      webhook: {
        id: '0',
        refund_line_items: [{
          id: 'refund_line_item_id',
          line_item: {
            variant_id: reward.redeemed_remote_variant_id,
            variant_title: 'Reward #12'
          }
        }]
      }
    }
  end

  let!(:job) { Shopify::RefundsCreateJob.new }

  describe '#perform' do
    it 'refunds the points of customer for every reward variant refunded' do
      expect_any_instance_of(LoyaltyLion).to receive(:add).with(points: 500, product_name: 'Alpcasso', action: 'refunded')
                                                          .and_return({ success: true })

      job.perform(args)
    end

    it 'updates the refunded_at of reward' do
      allow_any_instance_of(LoyaltyLion).to receive(:add).and_return({ success: true })

      expect(reward.refunded_at).to be_blank
      job.perform(args)
      expect(reward.reload.refunded_at).to be_present
    end
  end
end
