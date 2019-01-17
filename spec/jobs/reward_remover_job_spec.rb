require 'rails_helper'

describe RewardRemoverJob do
  let!(:shop) { create :shop }
  let!(:customer) { create :customer, shop: shop }

  before do
    ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop.shopify_domain, shop.shopify_token))
  end

  let!(:loyalty_lion) { instance_double(LoyaltyLion, points_approved: 1000, add: { success: true }) }
  let!(:product_json) { JSON.parse(File.read('spec/fixtures/shopify_product.json')) }
  let!(:shopify_product) { ShopifyAPI::Product.new(product: product_json) }
  let!(:referenced_variant) { shopify_product.variants.first }
  let!(:reward_variant) { ShopifyAPI::Variant.new(variant: { id: 'reward_variant_id' }) }
  let!(:local_product) { create :product, shop: shop, remote_id: shopify_product.id, points_cost: 500, title: shopify_product.title }

  let!(:remover) { RewardRemoverJob.new }

  before do
    create :product_variant, remote_id: referenced_variant.id, product: local_product
    create :reward, customer: customer, redeemed_remote_variant_id: reward_variant.id, referenced_remote_variant_id: referenced_variant.id
    shopify_product.variants << reward_variant
    allow(ShopifyAPI::Product).to receive(:find).and_return(shopify_product)
    allow(shopify_product).to receive(:save).and_return(true)
    allow(remover).to receive(:loyalty_lion).and_return(loyalty_lion)
    allow(RewardRestorerJob).to receive(:perform_later)
  end

  describe '#perform' do
    it 'adds the loyalty lion points back to the customer' do
      expect(loyalty_lion).to receive(:add).with(points: 500, product_name: shopify_product.title)

      remover.perform(shop_id: shop.id, customer_id: customer.remote_id, product_id: shopify_product.id, variant_id: reward_variant.id)
    end

    it 'deletes the reward' do
      expect {
        remover.perform(shop_id: shop.id, customer_id: customer.remote_id, product_id: shopify_product.id, variant_id: reward_variant.id)
      }.to change(Reward, :count).by(-1)
    end
  end
end
