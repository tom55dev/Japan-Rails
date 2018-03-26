class SpecialOffer < ApplicationRecord
  belongs_to :product
  belongs_to :shop

  validates :ends_at, presence: true
end
