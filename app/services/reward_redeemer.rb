class RewardRedeemer
  attr_reader :shop, :product_id, :variant_id, :customer_id

  def initialize(shop:, product_id:, variant_id:, customer_id:)
    @shop = shop
    @product_id = product_id
    @variant_id = variant_id
    @customer_id = customer_id
  end

  def call
    shop.with_shopify_session do
      redeem!
    end
  end

  private

  def product
    @product ||= ShopifyAPI::Product.find(product_id)
  end

  def current_variant
    @current_variant ||= product.variants.find { |v| v.id == variant_id }
  end

  def redeem!
    if current_variant.inventory_quantity > 0
      create_variant!
    else
      { success: false, error: 'Sorry, you cannot redeem this product anymore.' }
    end
  end

  def create_variant!
    current_variant.inventory_quantity -= 1
    product.variants << reward_variant

    if product.save
      created_variant = product.variants.find { |v| v.option1 == reward_variant.option1 }
      { variant_id: created_variant.id, success: true, error: nil }
    else
      { success: false, error: 'Sorry, a problem occured while claiming this product.' }
    end
  end

  def reward_variant
    @reward_variant ||= ShopifyAPI::Variant.new(variant_params)
  end

  def variant_params
    variant_attrs.merge(default_attrs)
  end

  def variant_attrs
    current_variant.attributes.slice(
      'sku', 'position', 'inventory_policy', 'fulfillment_service',
      'inventory_management', 'weight', 'weight_unit', 'image_id'
    ).symbolize_keys
  end

  def default_attrs
    {
      price: 0,
      compare_at_price: 0,
      option1: variant_title,
      inventory_quantity: 1,
      metafields: [customer_metafield]
    }.as_json
  end

  def variant_title
    if current_variant.title == 'Default Title'
      "Reward ##{Time.zone.now.to_i}"
    else
      "#{current_variant.title} (Reward ##{Time.zone.now.to_i})"
    end
  end

  def customer_metafield
    ShopifyAPI::Metafield.new({
      namespace: 'points_market',
      key: 'customer_id',
      value_type: 'integer',
      value: customer_id
    })
  end
end
