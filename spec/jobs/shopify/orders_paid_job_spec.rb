require 'rails_helper'

describe Shopify::OrdersPaidJob do
  let!(:shop) { create :shop }
  let!(:customer) { create :customer, shop: shop }

  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token))
  end

  let!(:reward) { create :reward, customer: customer, purchased_at: nil }
  let!(:args) do
    {
      shop_domain: shop.shopify_domain,
      webhook: {
        id: '0',
        created_at: '2018-01-01 00:00:00 JST',
        transactions: [],
        line_items: [{
          variant_id: reward.redeemed_remote_variant_id
        }]
      }
    }
  end

  let!(:shopify_order) { ShopifyAPI::Order.new(args[:webhook]) }
  let!(:shopify_reward_variant) { instance_double(ShopifyAPI::Variant, destroy: nil) }

  before do
    allow(ShopifyAPI::Order).to receive(:new).and_return(shopify_order)
    allow(ShopifyAPI::Variant).to receive(:find).with(reward.redeemed_remote_variant_id).and_return(shopify_reward_variant)
    allow(shopify_order).to receive(:transactions).and_return([])
  end

  describe '#perform' do
    context 'when there is a reward variant' do
      it 'updates the purchased_at of reward' do
        Shopify::OrdersPaidJob.new.perform(args)

        expect(reward.reload.purchased_at).to be_present
      end

      it 'destroys the reward variant' do
        expect(shopify_reward_variant).to receive(:destroy)

        Shopify::OrdersPaidJob.new.perform(args)
      end
    end

    context 'when there is no reward variant' do
      let!(:args) do
        {
          shop_domain: shop.shopify_domain,
          webhook: {
            id: '0',
            created_at: '2018-01-01 00:00:00 JST',
            transactions: [],
            line_items: [{
              variant_id: 'some-other-variant'
            }]
          }
        }
      end

      it 'does nothing' do
        expect(ShopifyAPI::Variant).not_to receive(:find)

        Shopify::OrdersPaidJob.new.perform(args)

        expect(reward.reload.purchased_at).to be_blank
      end
    end
  end
end
