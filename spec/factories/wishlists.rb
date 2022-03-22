FactoryBot.define do
  factory :wishlist do
    shop { create :shop }
    customer { create :customer }
    name { 'My Private Wishlist' }
    wishlist_type { 'private' }
  end
end
