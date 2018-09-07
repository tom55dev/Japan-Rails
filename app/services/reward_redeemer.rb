class RewardRedeemer
  attr_reader :shop, :product_id, :variant_id, :customer_id, :created_variant

  def initialize(shop:, product_id:, variant_id:, customer_id:)
    @shop = shop
    @product_id = product_id
    @variant_id = variant_id
    @customer_id = customer_id
  end

  def call
    shop.with_shopify_session do
      if variant_points_cost <= 0 || remote_variant.inventory_quantity <= 0
        { success: false, error: 'Oops, sorry you cannot redeem this product anymore.' }
      elsif loyalty_lion.points_approved < variant_points_cost
        { success: false, error: 'Sorry, you don\'t have enough points to redeem this product.' }
      else
        redeem!
      end
    end
  end

  private

  def remote_product
    @remote_product ||= ShopifyAPI::Product.find(product_id)
  end

  def remote_variant
    @remote_variant ||= remote_product.variants.find { |v| v.id == variant_id }
  end

  def customer
    @customer ||= Customer.find_by(remote_id: customer_id)
  end

  def loyalty_lion
    @loyalty_lion ||= LoyaltyLion.new(customer)
  end

  def variant_points_cost
    # Points are in the product metafield
    @variant_points ||= remote_product.metafields.find do |m|
      m.namespace == 'points_market' &&  m.key == 'points_cost'
    end&.value || 0
  end

  def redeem!
    result = create_variant!

    if result[:success]
      lion = loyalty_lion.deduct(points: variant_points_cost, product_name: remote_product.title)
      lion[:success] ? result : (created_variant.destroy and lion) # Might need to push on worker to ensure variant destroys
    else
      result
    end
  end

  def create_variant!
    remote_variant.inventory_quantity -= 1
    remote_product.variants << reward_variant

    if remote_product.save
      @created_variant = remote_product.variants.find { |v| v.option1 == reward_variant.option1 }

      { variant_id: created_variant.id, success: true, error: nil }
    else
      # Rarely happens, usually if there's a concurrency request it will make the variant negative in quantity
      # There's also a possiblity this will happen if shopify receives too many request on the API
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
    remote_variant.attributes.slice(
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
    }
  end

  def variant_title
    if remote_variant.title == 'Default Title'
      "Reward ##{Time.zone.now.to_i}"
    else
      "#{remote_variant.title} (Reward ##{Time.zone.now.to_i})"
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
