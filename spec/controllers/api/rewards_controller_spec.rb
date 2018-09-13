require 'rails_helper'

describe Api::RewardsController do
  let!(:shop) { create :shop }
  let!(:customer) { create :customer, shop: shop }

  let!(:params) do
    {
      shop: shop.shopify_domain,
      customer_id: customer.remote_id,
      user_uuid: 'some-uuid',
      product_id: '0',
      variant_id: '0'
    }
  end

  before do
    allow(StreaksCustomerAuthenticator).to receive(:new).with(
      shop, customer_id: customer.remote_id, user_uuid: 'some-uuid'
    ).and_return -> { true }
  end

  describe 'POST redeem' do
    it 'calls the RewardRedeemer' do
      expect_any_instance_of(RewardRedeemer).to receive(:call)

      post :redeem, params: params
    end

    context 'when authentication fails' do
      it 'returns an error' do
        expect(StreaksCustomerAuthenticator).to receive(:new).and_return -> { false }
        expect(RewardRedeemer).not_to receive(:new)

        post :redeem, params: params
        expect(JSON.parse(response.body)['error']).to be_present
      end
    end
  end

  describe 'POST remove' do
    it 'calls the RewardRemoverJob' do
      expect(RewardRemoverJob).to receive(:perform_later).with(shop.id, customer.remote_id, '0', '0')

      post :remove, params: params
    end

    context 'when authentication fails' do
      it 'returns an error' do
        expect(StreaksCustomerAuthenticator).to receive(:new).and_return -> { false }
        expect(RewardRemoverJob).not_to receive(:perform_later)

        post :redeem, params: params
        expect(JSON.parse(response.body)['error']).to be_present
      end
    end
  end
end
