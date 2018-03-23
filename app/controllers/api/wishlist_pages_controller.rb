class Api::WishlistPagesController < ApiController
  before_action :set_wishlist
  before_action :check_access!

  def show
    render json: {
      wishlist: serialized_wishlist,
      products: serialized_products,
      customer: {
        initials: @wishlist.customer.initials,
        first_name: @wishlist.customer.first_name
      },
      wishlists: wishlists
    }
  end

  private

  def set_wishlist
    if params[:customer_id].present?
      @wishlist = current_shop.wishlists.joins(:customer).distinct.where(customers: { remote_id: params[:customer_id] }).find_by(wishlists: { token: params[:id] })
    else
      @wishlist = current_shop.wishlists.where(wishlist_type: 'public').find_by(token: params[:id])
    end
  end

  def check_access!
    if @wishlist.blank?
      render json: 'wishlist not found', status: 404
    end
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
    wishlists = current_shop.wishlists.joins(:customer).where(customers: { remote_id: params[:customer_id] })
                                      .distinct
                                      .includes(:products)

    renderer.render(wishlists, class: { Wishlist: SerializableWishlist })[:data]
  end

  def renderer
    @renderer ||= JSONAPI::Serializable::Renderer.new
  end
end
