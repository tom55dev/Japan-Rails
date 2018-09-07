require 'rails_helper'

describe LoyaltyLion do
  let!(:shop) { create :shop }
  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token))
  end

  let!(:customer) { create :customer, remote_id: '123' }

  let!(:loyalty_lion) { LoyaltyLion.new(customer) }
  let!(:point_params) { { points: 500, product_name: 'test' } }
  let!(:lion_metafield) { ShopifyAPI::Metafield.new(resource: 'customers', resource_id: customer.remote_id, namespace: 'loyaltylion', key: 'points_approved', value: 1_000, value_type: 'integer') }
  before do
    allow(ShopifyAPI::Metafield).to receive(:where).and_return([lion_metafield])
  end

  describe '#add' do
    it 'adds the points on customer\'s loyaltylion account' do
      payload = { points: 500, reason: 'Reward removed from cart: test' }.to_json
      resp = double(:response, code: 201, body: '')
      expect(RestClient).to receive(:post).with(/points/, payload, { accept: 'json', content_type: 'json' }).and_yield(resp)

      loyalty_lion.add(point_params)
    end

    it 'returns success=true' do
      resp = double(:response, code: 201, body: '')
      allow(RestClient).to receive(:post).and_yield(resp)

      expect(loyalty_lion.add(point_params)).to eq ({ success: true, error: nil })
    end
  end

  describe '#deduct' do
    it 'returns success=true' do
      resp = double(:response, code: 201, body: '')
      allow(RestClient).to receive(:post).and_yield(resp)

      expect(loyalty_lion.deduct(point_params)).to eq ({ success: true, error: nil })
    end

    it 'deducts the points on customer\'s loyaltylion account' do
      payload = { points: 500, reason: 'Reward redeemed: test' }.to_json
      resp = double(:response, code: 201, body: '')

      expect(RestClient).to receive(:post).with(/remove_points/, payload, { accept: 'json', content_type: 'json' }).and_yield(resp)

      loyalty_lion.deduct(point_params)
    end

    context 'when points approved is not enough' do
      it 'returns success:false and gives an error message' do
        lion_metafield.value = 100
        expect(loyalty_lion.deduct(point_params)).to eq ({ success: false, error: 'Sorry, you don\'t have enough points to claim this reward.' })
      end
    end
  end
end
