require 'rails_helper'

describe WishlistCreator do
  let!(:shop) { create :shop }
  let!(:product) { create :product }
  let!(:manual_params) do
    {
      shop: shop,
      form_type: 'manual',
      customer_id: '123123',
      name: 'test',
      wishlist_type: 'public'
    }
  end
  let!(:auto_params) do
    {
      shop: shop,
      form_type: 'auto',
      customer_id: '123123',
      product_ids: [product.remote_id]
    }
  end

  before do
    json = JSON.parse File.read('spec/fixtures/shopify_customer.json')
    object = ShopifyAPI::Customer.new(customer: json)

    allow(ShopifyAPI::Customer).to receive(:find).and_return(object)
  end

  describe '#call' do
    context 'form_type is manual' do
      it 'creates the wishlist' do
        expect {
          WishlistCreator.new(manual_params).call
        }.to change(Wishlist, :count).by(1)
      end

      it 'does not create wishlist items' do
        expect {
          WishlistCreator.new(manual_params).call
        }.to change(WishlistItem, :count).by(0)
      end
    end

    context 'form_type is auto' do
      it 'creates the wishlist' do
        expect {
          WishlistCreator.new(auto_params).call
        }.to change(Wishlist, :count).by(1)
      end

      it 'creates the wishlist items' do
        expect {
          WishlistCreator.new(auto_params).call
        }.to change(WishlistItem, :count).by(1)
      end
    end
  end
end
