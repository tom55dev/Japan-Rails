require 'rails_helper'

describe LoyaltyLion do
  let!(:shop) { create :shop }
  let!(:customer) { create :customer, remote_id: '123' }

  let!(:loyalty_lion) { LoyaltyLion.new(shop, customer) }
  let!(:point_params) { { points: 500, product_name: 'test' } }

  describe '#add' do
    it 'adds the points on customer\'t loyaltylion account' do
      payload = { points: 500, reason: 'Reward: test' }.to_json
      resp = double(:response, code: 201, body: '')
      expect(RestClient).to receive(:post).with('https://:@/v2/customers/123/points', payload, { accept: 'json', content_type: 'json' }).and_yield(resp)

      loyalty_lion.add(point_params)
    end

    it 'returns success=true' do
      resp = double(:response, code: 201, body: '')
      allow(RestClient).to receive(:post).and_yield(resp)

      expect(loyalty_lion.add(point_params)).to eq ({ success: true, error: nil })
    end
  end

  describe '#deduct' do
    before { allow(loyalty_lion).to receive(:points_approved).and_return(1_000) }

    it 'returns success=true' do
      resp = double(:response, code: 201, body: '')
      allow(RestClient).to receive(:post).and_yield(resp)

      expect(loyalty_lion.deduct(point_params)).to eq ({ success: true, error: nil })
    end

    context 'when points approved is not enough' do
      before { allow(loyalty_lion).to receive(:points_approved).and_return(100) }

      it 'returns success:false and gives an error message' do
        expect(loyalty_lion.deduct(point_params)).to eq ({ success: false, error: 'Sorry, you don\'t have enough points to claim this reward.' })
      end
    end
  end
end
