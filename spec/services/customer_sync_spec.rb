require 'rails_helper'

describe CustomerSync do
  before do
    ShopifyAPI::Base.activate_session(
      ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token)
    )
  end

  let!(:shop) { create :shop }
  let!(:json) { JSON.parse File.read('spec/fixtures/shopify_customer.json') }
  let!(:shopify_customer) { ShopifyAPI::Customer.new(customer: json) }

  before do
    allow(ShopifyAPI::Customer).to receive(:find).and_return(shopify_customer)
  end

  describe '#call' do
    context 'when customer already exist' do
      before do
        create :customer, shop: shop, remote_id: shopify_customer.id
      end

      it 'updates the customer' do
        expect_any_instance_of(Customer).to receive(:update!)
        CustomerSync.new(shop, shopify_customer.id).call
      end

      it 'does not create a new customer' do
        expect {
          CustomerSync.new(shop, shopify_customer.id).call
        }.to change(Customer, :count).by(0)
      end
    end

    context 'when customer does not exist' do
      it 'creates a new customer' do
        expect {
          CustomerSync.new(shop, shopify_customer.id).call
        }.to change(Customer, :count).by(1)
      end
    end
  end
end
