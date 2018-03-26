class SpecialOffersController < ShopifyController
  before_action :set_special_offer

  def edit
  end

  def update
    create_or_update

    if @special_offer.persisted? && @special_offer.errors.blank?
      SpecialOfferSyncJob.perform_later(@special_offer.id)
      redirect_to root_path, flash: { notice: 'Special offer updated.' }
    else
      render :edit
    end
  end

  def search
    render json: {
      products: Product.where('title LIKE ?', "%#{params[:q]}%").limit(100)
    }
  end

  private

  def set_special_offer
    @special_offer = current_shop.special_offer || current_shop.build_special_offer
  end

  def special_offer_params
    params[:special_offer][:ends_at] = Time.zone.parse(params[:special_offer][:ends_at]) if params[:special_offer].present? && params[:special_offer][:ends_at].present?
    params.require(:special_offer).permit(:product_id, :ends_at)
  end

  def create_or_update
    if current_shop.special_offer.present?
      @special_offer = current_shop.special_offer
      @special_offer.update(special_offer_params)
    else
      @special_offer = current_shop.create_special_offer(special_offer_params)
    end
  end
end
