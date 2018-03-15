class WishlistItem < ApplicationRecord
  belongs_to :wishlist

  validates :product_id, uniqueness: { scope: [:wishlist_id] }
end
