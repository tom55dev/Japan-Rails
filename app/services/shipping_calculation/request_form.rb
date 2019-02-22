class ShippingCalculation::RequestForm
  include ActiveModel::Model
  DEFAULT_MAXIMUM_WEIGHT = 2000
  GRAMS_PER_POUND  = 453.592

  attr_accessor :country, :state, :postal_code, :weight_unit, :weight_value, :rates
  validates :country, :weight_unit, :weight_value, presence: true

  def create
    return false unless valid?

    items = ShippingCalculation::SampleLineItemBuilder.new(weight_in_grams: weight_in_grams).call

    api_result = ShippingCalculation::OMSApiClient.new.calculate_shipping(country_code, items)
    @rates = build_rates(api_result)
    true
  rescue ShippingCalculation::OMSApiClient::Error => e
    errors.add(:base, 'Sorry, your request could not be submitted. Please try again later.')
    false
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
    end.sort.map(&:represent)
  end

  def country_code
    ::Country.find_country_by_name(country)&.alpha2 || country
  end
end