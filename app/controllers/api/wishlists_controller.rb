class Api::WishlistsController < ApiController
  def create
    creator = WishlistCreator.new(dynamic_params)
    wishlist = creator.call

    if creator.errors.blank?
      render json: wishlist
    else
      render json: creator.errors, status: 400
    end
  end

  def update
    wishlist = Wishlist.find_by(token: params[:id])

    if wishlist.update(wishlist_params)
      render json: wishlist
    else
      render json: wishlist.errors, status: 400
    end
  end

  def destroy
    wishlist = Wishlist.find_by(token: params[:id])

    wishlist.destroy

    render json: 'ok', status: 200
  end

  private

  def dynamic_params
    params.permit!.merge({
      shop: Shop.find_by(shopify_domain: params[:shop]),
    })
  end

  def wishlist_params
    params.require(:wishlist).permit(:name, :wishlist_type)
  end
end
