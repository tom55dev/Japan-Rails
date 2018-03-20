class Api::WishlistPagesController < ApiController
  before_action :set_wishlist
  before_action :check_access!
  before_action :set_customer

  def show
    render json: {
      wishlist: serialized_wishlist,
      products: serialized_products,
      customer: {
        initials: customer_initials,
        first_name: @customer.first_name
      },
      wishlists: wishlists
    }
  end

  private

  def set_wishlist
    if params[:customer_id].present?
      @wishlist = current_shop.wishlists.where(shopify_customer_id: params[:customer_id]).find_by(token: params[:id])
    else
      @wishlist = current_shop.wishlists.where(wishlist_type: 'public').find_by(token: params[:id])
    end
  end

  def check_access!
    if @wishlist.blank?
      render json: 'wishlist not found', status: 404
    end
  end

  def set_customer
    shop_session = ShopifyAPI::Session.new(current_shop.shopify_domain, current_shop.shopify_token)
    ShopifyAPI::Base.activate_session(shop_session)

    @customer = ShopifyAPI::Customer.find(@wishlist.shopify_customer_id)
    ShopifyAPI::Base.clear_session
  end

  def serialized_wishlist
    json = renderer.render(@wishlist, class: { Wishlist: SerializableWishlist })

    json[:data]
  end

  def serialized_products
    products = @wishlist.products.includes(:product_variants)
    arr = renderer.render(products, class: { Product: SerializableProduct })[:data]

    arr.map do |json|
      { id: json[:id] }.merge(json[:attributes])
    end
  end

  def customer_initials
    [
      @customer.first_name.to_s[0].try(:upcase),
      @customer.last_name.to_s[0].try(:upcase)
    ].compact.join
  end

  def wishlists
    wishlists = current_shop.wishlists.where(shopify_customer_id: params[:customer_id])
                                      .includes(:products)

    renderer.render(wishlists, class: { Wishlist: SerializableWishlist })[:data]
  end

  def renderer
    @renderer ||= JSONAPI::Serializable::Renderer.new
  end
end
