class Api::RewardsController < ApiController
  before_action :authenticate_streaks_customer

  def redeem
    redeemer = RewardRedeemer.new(redeem_params.merge(shop: current_shop))

    render json: redeemer.call
  end

  def remove
    RewardRemoverJob.perform_later(current_shop.id, params[:customer_id], params[:product_id], params[:variant_id])

    product = Product.find_by(remote_id: params[:product_id])

    render json: { success: true, points: product&.points_cost || 0 }
  end

  private

  def authenticate_streaks_customer
    unless StreaksCustomerAuthenticator.new(customer_id: params[:customer_id], user_uuid: params[:user_uuid]).call
      render json: { success: false, error: "Sorry, it looks like you aren't on a streak. If you've just started one please wait a few minutes and try again." }
    end
  end

  def redeem_params
    params.permit(:product_id, :variant_id, :customer_id).as_json.symbolize_keys
  end
end
