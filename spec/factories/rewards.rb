FactoryBot.define do
  factory :reward do
    customer
    redeemed_remote_variant_id '0'
    referenced_remote_variant_id '0'
  end
end
