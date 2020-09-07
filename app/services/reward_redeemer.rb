class RewardRedeemer
  EXPIRATION_TIME = 2.hours

  attr_reader :shop, :product_id, :variant_id, :customer_id

  def initialize(shop:, product_id:, variant_id:, customer_id:)
    @shop = shop
    @product_id = product_id
    @variant_id = variant_id
    @customer_id = customer_id
  end

  def call
    shop.with_shopify_session do
      if product_points_cost <= 0
        { success: false, error: 'Oops, sorry you cannot redeem this product anymore.' }
      elsif remote_variant.inventory_quantity <= 0
        { success: false, error: 'Oops, sorry this product is out of stock.' }
      elsif loyalty_lion.points_approved < product_points_cost
        { success: false, error: 'Sorry, you don\'t have enough points to redeem this product.' }
      else
        ActiveRecord::Base.transaction { redeem! }
        # better not use transaction? and check in rescue if reward exist
      end
    end
  rescue LoyaltyLion::CannotFetchPointsError => e
    AppSignal.set_error(e)

    { success: false, error: "Sorry, we couldn't confirm your eligibility. Please try again in a few minutes." }
  end

  private

  def remote_product
    @remote_product ||= ShopifyAPI::Product.find(product_id)
  end

  def remote_variant
    @remote_variant ||= remote_product.variants.find { |v| v.id == variant_id.to_i }
  end

  def remote_inventory_level
    @remote_inventory_level ||= ShopifyAPI::InventoryLevel.where(inventory_item_ids: remote_variant.inventory_item_id).first
  end

  def customer
    @customer ||= CustomerFinder.new(shop, customer_id).call
  end

  def reward
    @reward ||= customer.rewards.create!(
      redeemed_remote_variant_id: reward_variant.id,
      referenced_remote_variant_id: remote_variant.id
    )
  end

  def loyalty_lion
    @loyalty_lion ||= LoyaltyLion.new(customer)
  end

  def product_points_cost
    @product_points_cost ||= shop.products.find_by(remote_id: remote_product.id).points_cost
  end

  def redeem!
    result = create_variant!

    result[:success] ? record_on_loyalty_lion!(result) : result
  end

  def create_variant!
    remote_inventory_level # Preload remote_inventory_level
    remote_variant_deducted = false

    if reward_variant.save
      remote_variant_deducted = true if remote_inventory_level.adjust(-1)

      reward_inventory_level = ShopifyAPI::InventoryLevel.new(
        inventory_item_id: reward_variant.inventory_item_id,
        location_id: remote_inventory_level.location_id,
        available: 0
      )
      reward_inventory_level.adjust(1)

      { variant_id: reward_variant.id, remaining_quantity: (remote_variant.inventory_quantity - 1), success: true, error: nil }
    else
      # Rarely happens, usually if there's a concurrency request it will make the variant negative in quantity
      # There's also a possiblity this will happen if shopify receives too many request on the API
      { success: false, error: 'Sorry, a problem occured while claiming this product.' }
    end
  rescue => e
    # Restores the remote variant (product) to its original state before redeeming
    if e.respond_to?(:response) && e.response.code == 429
      if reward_variant.persisted?
        RewardRestorerJob.perform_later(
          shop_id: shop.id,
          remote_variant_id: remote_variant_id,
          reward_variant_id: reward_variant.id,
          remote_variant_deducted: remote_variant_deducted
        )
      end

      { success: false, error: 'Sorry, a problem occured while claiming this product.' }
    else
      raise e
    end
  end

  def record_on_loyalty_lion!(result)
    lion = loyalty_lion.deduct(points: product_points_cost, product_name: remote_product.title)
    if lion[:success]
      RewardExpiryJob.set(wait: EXPIRATION_TIME).perform_later(reward.id)
      result
    else
      remove_created_variant! and lion
    end
  end

  def remove_created_variant!
    RewardRemoverJob.perform_later(
      shop_id: shop.id,
      customer_id: customer.remote_id,
      product_id: remote_product.id,
      variant_id: reward_variant.id,
      add_points: false
    )
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
      product_id: remote_product.id,
      price: 0,
      compare_at_price: 0,
      option1: variant_title,
      metafields: [customer_metafield]
    }
  end

  def variant_title
    id = Time.zone.now.to_i + customer.id
    if remote_variant.title == 'Default Title'
      "Reward ##{id}"
    else
      "#{remote_variant.title} (Reward ##{id})"
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
