class Api::WishlistsController < ApiController
  def index
    wishlists = current_shop.wishlists.where(shopify_customer_id: params[:customer_id])
                                      .includes(:products)
                                      .order(created_at: :desc)

    render jsonapi: wishlists
  end

  def create
    creator = WishlistCreator.new(dynamic_params)
    wishlist = creator.call

    if creator.errors.blank?
      render jsonapi: wishlist, include: [:wishlist_items]
    else
      render json: creator.errors, status: 400
    end
  end

  def update
    wishlist = current_shop.wishlists.find_by(token: params[:id])

    if wishlist.update(wishlist_params)
      render jsonapi: wishlist, include: [:wishlist_items]
    else
      render json: wishlist.errors, status: 400
    end
  end

  def destroy
    wishlist = current_shop.wishlists.find_by(token: params[:id])

    wishlist.destroy

    render json: 'ok', status: 200
  end

  # Wishlist Items
  def add_product
    wishlist = find_wishlist

    item = wishlist.wishlist_items.create(product: product)

    if item.persisted?
      render jsonapi: wishlist
    else
      render json: item.errors, status: 400
    end
  end

  def remove_product
    wishlist = find_wishlist
    item = wishlist.wishlist_items.find_by(product: product)

    item.destroy

    render json: item
  end

  private

  def dynamic_params
    {
      shop: current_shop,
      customer_id: params[:customer_id],
      form_type: params[:form_type],
      product_ids: params[:product_ids]
    }
  end

  def wishlist_params
    params.require(:wishlist).permit(:name, :wishlist_type)
  end

  def find_wishlist
    model = current_shop.wishlists.find_by(token: params[:id])

    model = create_wishlist if model.blank?
    model
  end

  def wishlist_params
    Wishlist.create({
      shopify_customer_id: params[:customer_id],
      name: product.title, # default
      wishlist_type: 'private', # default
    })
  end

  def product
    @product ||= Product.find_by(remote_id: params[:product_id])
  end
end
