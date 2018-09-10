require 'rails_helper'

describe RewardRedeemer do
  let!(:shop) { create :shop }
  let!(:customer) { create :customer }

  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token))
  end

  let!(:product_json) { JSON.parse(File.read('spec/fixtures/shopify_product.json')) }
  let!(:shopify_product) { ShopifyAPI::Product.new(product: product_json) }
  let!(:current_variant) { shopify_product.variants.first }
  let!(:market_metafield) { ShopifyAPI::Metafield.new(namespace: 'points_market', key: 'points_cost', value: 500, value_type: 'integer') }
  let!(:redeem_params) do
    { shop: shop, customer_id: customer.remote_id, product_id: shopify_product.id, variant_id: current_variant.id }
  end
  let!(:loyalty_lion) { instance_double(LoyaltyLion, points_approved: 1000, deduct: { success: true }) }

  let!(:redeemer) { RewardRedeemer.new(redeem_params) }

  before do
    current_variant.inventory_quantity = 10
    allow(ShopifyAPI::Product).to receive(:find).and_return(shopify_product)
    allow(shopify_product).to receive(:metafields).and_return([market_metafield])
    allow(shopify_product).to receive(:save).and_return(true)
    allow(redeemer).to receive(:loyalty_lion).and_return(loyalty_lion)
    allow(redeemer).to receive(:created_variant).and_return(ShopifyAPI::Variant.new(id: 'created_variant_id'))
    allow(RewardRemoverJob).to receive(:perform_later).and_return(true)
  end

  describe '#call' do
    it 'creates a new variant with reward option' do
      expect {
        redeemer.call
      }.to change(shopify_product.variants, :count).by(1)
    end

    it 'creates a reward model' do
      expect {
        redeemer.call
      }.to change(Reward, :count).by(1)
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
      expect(redeemer.call).to eq({ variant_id: 'created_variant_id', success: true, error: nil })
    end

    context 'when variant save fails' do
      before do
        allow(shopify_product).to receive(:save).and_return(false)
      end

      it 'returns a success=false with error message' do
        expect(redeemer.call).to eq({ success: false, error: 'Sorry, a problem occured while claiming this product.' })
      end
    end

    context 'when you dont have enough points' do
      before do
        allow(redeemer).to receive(:loyalty_lion).and_return(instance_double(LoyaltyLion, points_approved: 100))
      end

      it 'returns a success=false with error message' do
        expect(redeemer.call).to eq ({ success: false, error: 'Sorry, you don\'t have enough points to redeem this product.' })
      end
    end

    context 'when inventory quantity is zero' do
      before do
        current_variant.inventory_quantity = 0
      end

      it 'returns a success=false with error message' do
        expect(redeemer.call).to eq ({ success: false, error: 'Oops, sorry you cannot redeem this product anymore.' })
      end
    end

    context 'when you successfully create a variant and lion doesnt have enough points' do
      let!(:lion_result) { { success: false, error: 'Sorry, you don\'t have enough points to claim this reward.' }}

      before do
        allow(redeemer).to receive(:loyalty_lion).and_return(instance_double(LoyaltyLion, points_approved: 1000, deduct: lion_result))

        allow_any_instance_of(ShopifyAPI::Variant).to receive(:destroy).and_return(true)
      end

      it 'returns the response from loyalty lion class' do
        expect(redeemer.call).to eq(lion_result)
      end

      it 'calls the reward remover job' do
        expect(RewardRemoverJob).to receive(:perform_later).with(customer.remote_id, shopify_product.id, 'created_variant_id')

        redeemer.call
      end
    end
  end
end
