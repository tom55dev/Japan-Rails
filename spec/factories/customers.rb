FactoryBot.define do
  factory :customer do
    shop { create :shop }
    remote_id '123123'
    email 'test@tokyotreat.com'
    first_name 'Test'
    last_name 'TokyoTreat'
    orders_count 1
  end
end
