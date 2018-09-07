require 'rails_helper'

describe RewardRedeemer do
  let!(:shop) { create :shop }

  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token))
  end

  let!(:product_json) { JSON.parse(File.read('spec/fixtures/shopify_product.json')) }
  let!(:shopify_product) { ShopifyAPI::Product.new(product: product_json) }
  let!(:current_variant) { shopify_product.variants.first }
  let!(:redeem_params) do
    { shop: shop, customer_id: 123, product_id: shopify_product.id, variant_id: current_variant.id }
  end

  let!(:redeemer) { RewardRedeemer.new(redeem_params) }

  before do
    current_variant.inventory_quantity = 10

    allow(ShopifyAPI::Product).to receive(:find).and_return(shopify_product)

    allow(shopify_product).to receive(:save).and_return(true)
  end

  describe '#call' do
    it 'creates a new variant with reward option' do
      expect {
        redeemer.call
      }.to change(shopify_product.variants, :count).by(1)
    end

    it 'builds the correct variant' do
      redeemer.call

      expect(shopify_product.variants.last.attributes).to include({
        sku: 'DAG-BOU-BURGER-SOLTYCALAMEL',
        position: 1,
        inventory_policy: 'deny',
        fulfillment_service: 'manual',
        inventory_management: 'shopify',
        weight: 87.0,
        weight_unit: 'g',
        image_id: nil,
        price: 0,
        compare_at_price: 0,
        option1: /Reward #/,
        inventory_quantity: 1,
        metafields: [
          ShopifyAPI::Metafield.new(namespace: 'points_market', key: 'customer_id', value_type: 'integer', value: 123)
        ]
      })
    end

    it 'reduces the selected variant inventory quantity' do
      redeemer.call

      expect(current_variant.inventory_quantity).to eq 9
    end

    it 'returns a success=true and variant_id key' do
      expect(redeemer.call).to eq({ variant_id: nil, success: true, error: nil })
    end

    context 'when save fails' do
      before do
        allow(shopify_product).to receive(:save).and_return(false)
      end

      it 'returns a success=false with error message' do
        expect(redeemer.call).to eq({ success: false, error: 'Sorry, a problem occured while claiming this product.' })
      end
    end

    context 'when inventory quantity is zero' do
      before do
        current_variant.inventory_quantity = 0
      end

      it 'returns a success=false with error message' do
        expect(redeemer.call).to eq ({ success: false, error: 'Sorry, you cannot redeem this product anymore.' })
      end
    end
  end
end
