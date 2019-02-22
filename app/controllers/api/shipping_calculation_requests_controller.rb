class Api::ShippingCalculationRequestsController < ApiController
  def create
    form = ShippingCalculation::RequestForm.new(shipping_calculation_request_params)
    if form.create
      render json: { success: true, data: form.rates }
    else
      render json: { success: false, error: { message: form.errors.full_messages.join(" "), details: form.errors.full_messages }}, status: 400
    end
  end

  private

  def shipping_calculation_request_params
    params.permit(:country, :state, :postal_code, :weight_unit, :weight_value)
  end
end