class OMSApi::ShippingCalculator
  def self.call
    api_key = "1x0JgXBhwlRrhuG4NM-JrEr0cQ0"
    api_base = 'http://oms.test/api'
    api_url = '/shipping/calculator'

    resp = RestClient.post("#{api_base}#{api_url}?api_key=#{api_key}", sample_payload.to_json, {content_type: :json, accept: :json})
    JSON.parse(resp.body)
  rescue => e
    e
  end

  private

  def self.sample_payload
    {
      rate: {
        destination: {
          country: 'JP',
          postal_code: '94102',
          provice: 'CA'
        },
        items: [{
          "quantity": 1,
          "grams": 1000,
          "price": 1,
        }],
        currency: "USD",
        locale: "en"
      }
    }
  end
end

# {
#   country: 'JP',
#   postal_code: '94102',
#   state: 'CA',
#   weight_value: 1,
#   weight_unit: 'grams'
# }

# Shopify Carrier Service sample payload
# {
#   "rate": {
#     "origin": {
#       "country": "CA",
#       "postal_code": "K2P1L4",
#       "province": "ON",
#       "city": "Ottawa",
#       "name": null,
#       "address1": "150 Elgin St.",
#       "address2": "",
#       "address3": null,
#       "phone": "16135551212",
#       "fax": null,
#       "email": null,
#       "address_type": null,
#       "company_name": "Jamie D's Emporium"
#     },
#     "destination": {
#       "country": "CA",
#       "postal_code": "K1M1M4",
#       "province": "ON",
#       "city": "Ottawa",
#       "name": "Bob Norman",
#       "address1": "24 Sussex Dr.",
#       "address2": "",
#       "address3": null,
#       "phone": null,
#       "fax": null,
#       "email": null,
#       "address_type": null,
#       "company_name": null
#     },
#     "items": [{
#       "name": "Short Sleeve T-Shirt",
#       "sku": "",
#       "quantity": 1,
#       "grams": 1000,
#       "price": 1999,
#       "vendor": "Jamie D's Emporium",
#       "requires_shipping": true,
#       "taxable": true,
#       "fulfillment_service": "manual",
#       "properties": null,
#       "product_id": 48447225880,
#       "variant_id": 258644705304
#     }],
#     "currency": "USD",
#     "locale": "en"
#   }
# }