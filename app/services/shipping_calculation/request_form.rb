class ShippingCalculation::RequestForm
  include ActiveModel::Model
  GRAMS_PER_POUND  = 453.592

  attr_accessor :country, :weight_unit, :weight_value, :rates
  validates :country, :weight_unit, :weight_value, presence: true

  def create
    return false unless valid?

    items = ShippingCalculation::SampleLineItemBuilder.new(weight_in_grams: weight_in_grams).call

    api_result = ShippingCalculation::OMSCalculator.new(country_code, items).call
    if api_result
      @rates = build_rates(api_result)
      true
    else
      errors.add(:base, 'Sorry, your request could not be submitted. Please try again later.')
      false
    end
  end

  private

  def weight_in_grams
    if weight_unit == 'grams'
      weight_value.to_i
    else
      weight_value.to_i * GRAMS_PER_POUND
    end
  end

  def build_rates(api_result)
    api_result['rates'].map do|rate|
      ShippingCalculation::ShippingRate.new(
        service_name: rate['service_name'],
        service_code: rate['service_code'],
        currency: rate['currency'],
        total_price: rate['total_price']
      )
    end.sort_by(&:total_price).map(&:represent)
  end

  def country_code
    ::Country.find_country_by_name(country)&.alpha2 || country
  end
end