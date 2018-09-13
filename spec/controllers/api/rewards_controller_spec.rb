require 'rails_helper'

describe Api::RewardsController do
  let!(:shop) { create :shop }
  let!(:customer) { create :customer, shop: shop }

  describe 'POST redeem' do
    it 'calls the RewardRedeemer' do
      expect_any_instance_of(RewardRedeemer).to receive(:call)

      post :redeem, params: { shop: shop.shopify_domain, customer_id: customer.remote_id, product_id: '0', variant_id: '0' }
    end
  end

  describe 'POST remove' do
    it 'calls the RewardRemoverJob' do
      expect(RewardRemoverJob).to receive(:perform_later).with(shop_id: shop.id, customer_id: customer.remote_id, product_id: '0', variant_id: '0')

      post :remove, params: { shop: shop.shopify_domain, customer_id: customer.remote_id, product_id: '0', variant_id: '0' }
    end
  end
end
