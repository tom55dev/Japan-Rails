class Api::WishlistPagesController < ApiController
  before_action :set_wishlist

  def show
    if @wishlist.present?
      render json: {
        wishlist: serialized_wishlist,
        products: serialized_products,
        customer: {
          initials: @wishlist.customer.initials,
          first_name: @wishlist.customer.first_name
        },
        wishlists: wishlists
      }
    else
      render json: 'wishlist not found', status: 404
    end
  end

  def product
    collection = current_shop.wishlists.joins(:products)
                                      .where(products: { remote_id: params[:product_id] })
                                      .where(wishlists: { wishlist_type: 'public' })
                                      .distinct
                                      .order('wishlists.updated_at DESC')
                                      .first(8)

    render jsonapi: collection, class: {
      Wishlist: SerializableProductWishlistPage,
      Customer: SerializableCustomer,
    }, include: :customer
  end

  private

  def set_wishlist
    if params[:customer_id].present?
      @wishlist = current_shop.wishlists.find_by(token: params[:id])
      @wishlist = nil if @wishlist.wishlist_type == 'private' && @wishlist.customer.remote_id != params[:customer_id]
    else
      @wishlist = current_shop.wishlists.where(wishlist_type: 'public').find_by(token: params[:id])
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
