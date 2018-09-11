class Customer < ApplicationRecord
  belongs_to :shop
  has_many :rewards, dependent: :destroy

  validates :remote_id, presence: true, uniqueness: { scope: :shop_id }

  def initials
    [
      first_name.to_s[0].try(:upcase),
      last_name.to_s[0].try(:upcase)
    ].compact.join
  end
end
