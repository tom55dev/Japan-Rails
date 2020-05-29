class OrderShippingController < ApiController
  def new
    unless call_api
      flash[:error] = 'Sorry, your request could not be submitted. Please try again later.'
    end

    render :thankyou
  end

  private

  def call_api
    resp = RestClient.post(
      api_url,
      order_shipping_params.to_json,
      content_type: :json,
      accept: :json
    )
    JSON.parse(resp.body)
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
