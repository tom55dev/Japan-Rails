require 'rails_helper'

describe LoyaltyLion do
  let!(:shop) { create :shop }
  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token))
  end

  let!(:customer) { create :customer, remote_id: '123' }

  let!(:loyalty_lion) { LoyaltyLion.new(customer) }
  let!(:point_params) { { points: 500, product_name: 'test' } }

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
    before { customer.update!(points_approved: 10000) }

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
      before { customer.update!(points_approved: 100) }

      it 'returns success:false and gives an error message' do
        expect(loyalty_lion.deduct(point_params)).to eq ({ success: false, error: 'Sorry, you don\'t have enough points to claim this reward.' })
      end
    end
  end

  describe '#points_approved' do
    context 'when points approved is set on the customer' do
      before { customer.update!(points_approved: 0) }

      it 'returns the field value' do
        expect(RestClient).not_to receive(:get)

        expect(loyalty_lion.points_approved).to eq 0
      end
    end

    context 'when points approved is not set' do
      let!(:response) do
        double(:response, code: 200, body: { customers: [{ merchant_id: customer.remote_id, points_approved: 123}] }.to_json)
      end

      before do
        expect(RestClient).to receive(:get).with(/customers/, headers: { params: { email: customer.email } }).and_yield(response)
      end

      it 'updates the points from LoyaltyLion' do
        expect(loyalty_lion.points_approved).to eq 123
        expect(customer.reload.points_approved).to eq 123
      end

      context 'and LoyaltyLion returns an error' do
        let!(:response) do
          double(:response, code: 403, body: { customers: [{ merchant_id: customer.remote_id, points_approved: 123}] }.to_json)
        end

        it 'raises the error' do
          expect { loyalty_lion.points_approved }.to raise_error(LoyaltyLion::CannotFetchPointsError, /403/)
        end
      end

      context 'and LoyaltyLion does not return the customer' do
        let!(:response) do
          double(:response, code: 200, body: { customers: [] }.to_json)
        end

        it 'raises an error' do
          expect { loyalty_lion.points_approved }.to raise_error(LoyaltyLion::CannotFetchPointsError, /#{customer.remote_id}/)
        end
      end
    end
  end
end
