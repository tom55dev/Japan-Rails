FactoryBot.define do
  factory :shop do
    sequence(:shopify_domain) { |n| "japan-gift-card-staging-#{n}.myshopify.com" }
    shopify_token { 'test-token-here' }
  end
end
