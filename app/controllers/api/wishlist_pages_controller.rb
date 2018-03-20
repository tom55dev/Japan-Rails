class Api::WishlistPagesController < ApiController
  before_action :set_wishlist
  before_action :set_customer

  def show
    render json: {
      wishlist: {
        id: @wishlist.token,
        name: @wishlist.name,
        type: @wishlist.wishlist_type,
        updated_at: @wishlist.updated_at.strftime('%B %d, %Y %l%p %Z')
      },
      products: serialize_products(@wishlist.products.includes(:product_variants)),
      customer: {
        initials: customer_initials,
        first_name: @customer.first_name
      }
    }
  end

  private

  def set_wishlist
    @wishlist = current_shop.wishlists.find_by(token: params[:id])
  end

  def set_customer
    return if @wishlist.blank?
    shop_session = ShopifyAPI::Session.new(current_shop.shopify_domain, current_shop.shopify_token)
    ShopifyAPI::Base.activate_session(shop_session)

    @customer = ShopifyAPI::Customer.find(@wishlist.shopify_customer_id)
    ShopifyAPI::Base.clear_session
  end

  def serialize_products(products)
    renderer = JSONAPI::Serializable::Renderer.new
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
end
