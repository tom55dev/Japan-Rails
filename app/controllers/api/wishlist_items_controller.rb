class Api::WishlistItemsController < ApiController
  def create
    wishlist = find_wishlist

    item = wishlist.wishlist_items.create(product_id: params[:product_id])

    if item.persisted?
      render json: { token: wishlist.token }
    else
      render json: item.errors, status: 400
    end
  end

  def destroy
    item = wishlist.wishlist_items.find_by(product_id: params[:product_id])

    item.destroy

    render json: item
  end

  private

  def product
    @product ||= ShopifyAPI::Product.find(params[:wishlist_item][:product_id])
  end

  def find_wishlist
    model = current_shop.wishlists.find_by(token: params[:wishlist_id])

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
end
