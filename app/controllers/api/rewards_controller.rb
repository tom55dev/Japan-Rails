class Api::RewardsController < ApiController
  def redeem
    redeemer = RewardRedeemer.new redeem_params.merge(shop: current_shop)

    render json: redeemer.call
  end

  def remove

  end

  private

  def redeem_params
    params.permit(:product_id, :variant_id, :customer_id)
  end
end
