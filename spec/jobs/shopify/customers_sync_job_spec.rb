require 'rails_helper'

describe Shopify::CustomersSyncJob do
  let!(:shop) { create :shop }

  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token))
  end

  let!(:args) do
    {
      shop_domain: shop.shopify_domain,
      webhook: {
        id: 706405506930370084,
        email: 'bob@biller.com',
        accepts_marketing: true,
        created_at: nil,
        updated_at: nil,
        first_name: 'Bob',
        last_name: 'Biller',
        orders_count: 0,
        state: 'disabled',
        total_spent: '0.00',
        last_order_id: nil,
        note: 'This customer loves ice cream',
        verified_email: true,
        multipass_identifier: nil,
        tax_exempt: false,
        phone: nil,
        tags: '',
        last_order_name: nil,
        addresses: []
      }
    }
  end

  describe '#perform' do
    it 'syncs the customer' do
      expect(CustomerSync).to receive(:new).with(
        shop, shopify_customer: an_instance_of(ShopifyAPI::Customer)
      ).and_call_original

      Shopify::CustomersSyncJob.new.perform(args)

      expect(Customer.last.email).to eq 'bob@biller.com'
    end
  end
end
