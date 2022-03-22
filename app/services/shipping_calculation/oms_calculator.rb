module ShippingCalculation
  class OMSCalculator
    class Error < StandardError; end;

    attr_reader :country, :items

    def initialize(country, items)
      @country = country
      @items = items
      @api_key = Rails.application.credentials.oms_api_key
      @api_base = Rails.application.credentials.oms_api_url
    end

    def call
      path = '/shopify/webhooks/shipping_methods/calculate'

      resp = RestClient.post(
        api_url(path),
        format_shipping_calc_params.to_json,
        {content_type: :json, accept: :json}
      )
      JSON.parse(resp.body)
    rescue RestClient::ExceptionWithResponse => e
      raise e if Rails.env.development?
      Sentry.capture_exception(e)
      false
    end

    private

    def format_shipping_calc_params
      {
        rate: {
          destination: {
            country: country
          },
          items: items.map(&:to_h),
          currency: "USD",
          locale: "en"
        }
      }
    end

    def api_url(path)
      "#{@api_base}#{path}?api_key=#{@api_key}"
    end
  end
end
