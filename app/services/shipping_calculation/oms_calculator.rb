module ShippingCalculation
  class OMSCalculator
    class Error < StandardError; end;

    def initialize(api_key = "")
      @api_key = Rails.application.secrets.oms_api_key
      @api_base = Rails.application.secrets.oms_api_url
    end

    def call(country, items)
      path = '/shipping/calculator'

      resp = RestClient.post(
        api_url(path),
        format_shipping_calc_params(country, items).to_json,
        {content_type: :json, accept: :json}
      )
      JSON.parse(resp.body)
    rescue RestClient::ExceptionWithResponse => e
      raise e if Rails.env.development?
      Appsignal.set_error(e)
      false
    end

    private

    def format_shipping_calc_params(country, items)
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