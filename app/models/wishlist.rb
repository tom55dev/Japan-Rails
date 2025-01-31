class Wishlist < ApplicationRecord
  belongs_to :shop
  belongs_to :customer

  has_many :wishlist_items, dependent: :destroy
  has_many :products, through: :wishlist_items

  validates :name, :token, :wishlist_type, presence: true

  before_validation :set_random_token, on: :create

  private

  def set_random_token
    loop do
      self.token = SecureRandom.urlsafe_base64(20)

      break unless Wishlist.exists?(token: token)
    end
  end
end
