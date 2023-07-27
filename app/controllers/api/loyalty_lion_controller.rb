class Api::LoyaltyLionController < ApiController
  def customer_updated
    customer_params = params[:payload][:customer]

    # LoyaltyLion::PointsUpdateJob.perform_later(
    #   shop: params[:shop],
    #   customer_id: customer_params[:merchant_id],
    #   points_approved: customer_params[:points_approved]
    # )

    head :ok
  end
end
