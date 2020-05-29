class OrderShippingController < ApplicationController
  def new
    if call_api
      @message = confirmation_message
    else
      @error = 'Sorry, your request could not be submitted. Please try again later.'
    end

    render :thankyou
  end

  private

  def confirmation_message
    if params[:cancelling].present?
      "We've fully refunded and cancelled your order."
    else
      "We've refunded you $#{params[:amount]} and your order will be reshipped with #{params[:shipping_method]}"
    end
  end

  def call_api
    RestClient.post(
      api_url,
      order_shipping_params.to_json,
      content_type: :json,
      accept: :json
    )
    response.status == 200
  rescue RestClient::ExceptionWithResponse => e
    raise e if Rails.env.development?
    Appsignal.set_error(e)
    false
  end

  def order_shipping_params
    params.permit(:order_id, :cancelling, :shipping_method, :amount)
  end

  def api_url
    "#{api_base}#{path}?api_key=#{api_key}"
  end

  def path
    '/shopify/order_refunds'
  end

  def api_key
    Rails.application.secrets.oms_api_key
  end

  def api_base
    Rails.application.secrets.oms_api_url
  end
end
