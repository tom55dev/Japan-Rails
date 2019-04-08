module ShippingCalculation
  class ShippingRate
    attr_accessor :service_name, :service_code, :currency, :total_price

    def initialize(service_name:, service_code:, currency:, total_price:)
      @service_name = service_name
      @service_code = service_code
      @currency     = currency
      @total_price  = total_price
    end

    def represent
      {
        plan_name: plan_name,
        estimate: estimate,
        price: total_price,
        currency: currency
      }
    end

    private

    def plan_name
      reg_ex = /(.*)\s\(/
      result = reg_ex.match(service_name)
      result && result[1]
    end

    def estimate
      reg_ex = /.*\((.*)\)/;
      result = reg_ex.match(service_name);
      result && result[1]
    end
  end
end