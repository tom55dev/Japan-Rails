require 'rails_helper'

describe StreaksCustomerAuthenticator do
  let!(:shop) { create :shop }

  let!(:customer_id) { '123456' }
  let!(:user_uuid) { 'some-uuid' }
  let!(:active_streak_count) { 1 }

  let!(:metafields) do
    shop.with_shopify_session do
      [
        ShopifyAPI::Metafield.new(namespace: 'customer_portal', key: 'user_uuid', value: user_uuid, value_type: 'string'),
        ShopifyAPI::Metafield.new(namespace: 'customer_portal', key: 'active_streak_count', value: active_streak_count, value_type: 'integer')
      ]
    end
  end

  let!(:authenticator) { StreaksCustomerAuthenticator.new(shop, customer_id: customer_id, user_uuid: user_uuid) }

  before do
    allow(ShopifyAPI::Metafield).to receive(:find).and_return(metafields)
  end

  context 'when the customer has an active streak' do
    it 'returns true' do
      expect(authenticator.call).to eq true
    end
  end

  context 'when the customer has no customer portal metafields' do
    let!(:metafields) { [] }

    it 'returns false' do
      expect(authenticator.call).to eq false
    end
  end

  context 'when the customer ID and uuid do not match' do
    let!(:authenticator) { StreaksCustomerAuthenticator.new(shop, customer_id: customer_id, user_uuid: 'something-else') }

    it 'returns false' do
      expect(authenticator.call).to eq false
    end
  end

  context 'when the customer has no active streaks' do
    let!(:active_streak_count) { 0 }

    it 'returns false' do
      expect(authenticator.call).to eq false
    end
  end
end
