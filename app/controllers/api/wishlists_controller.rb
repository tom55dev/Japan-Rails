class Api::WishlistsController < ApiController
  def index
    wishlists = filter_wishlists.includes(:products)
                                .order(created_at: :desc)

    render jsonapi: wishlists
  end

  def create
    creator = WishlistCreator.new(dynamic_params)
    wishlist = creator.call

    if creator.errors.blank?
      render jsonapi: wishlist
    else
      render json: creator.errors, status: 400
    end
  end

  def update
    wishlist = filter_wishlists.find_by(token: params[:id])

    if wishlist.update(wishlist_params)
      render jsonapi: wishlist
    else
      render json: wishlist.errors, status: 400
    end
  end

  def show
    if params[:id] == 'latest'
      render jsonapi: filter_wishlists.order(created_at: :desc).first
    else
      render jsonapi: filter_wishlists.find_by(token: params[:id])
    end
  end

  def destroy
    wishlist = filter_wishlists.find_by(token: params[:id])

    wishlist.destroy

    render json: 'ok', status: 200
  end

  # Wishlist Items
  def add_product
    wishlist = current_wishlist
    item = current_wishlist.wishlist_items.create(product: product)

    if item.persisted?
      current_wishlist.update(updated_at: Time.zone.now)
      render jsonapi: wishlist
    else
      render json: item.errors, status: 400
    end
  end

  def remove_product
    wishlist = current_wishlist
    item = current_wishlist.wishlist_items.find_by(product: product)
    current_wishlist.update(updated_at: Time.zone.now)

    item.destroy

    render jsonapi: wishlist
  end

  private

  def dynamic_params
    {
      shop: current_shop,
      customer_id: params[:customer_id],
      form_type: params[:form_type],
      product_ids: params[:product_ids],
      name: params[:name],
      wishlist_type: params[:wishlist_type]
    }
  end

  def wishlist_params
    params.require(:wishlist).permit(:name, :wishlist_type)
  end

  def filter_wishlists
    current_shop.wishlists.where(shopify_customer_id: params[:customer_id])
  end

  def current_wishlist
    @current_wishlist ||= filter_wishlists.find_by(token: params[:id])
  end

  def product
    @product ||= Product.find_by(remote_id: params[:product_id])
  end
end
