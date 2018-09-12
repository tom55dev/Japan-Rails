class Api::RewardsController < ApiController
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

  def redeem_params
    params.permit(:product_id, :variant_id, :customer_id).as_json.symbolize_keys
  end
end
