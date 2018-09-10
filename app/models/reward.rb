class Reward < ApplicationRecord
  belongs_to :customer
  belongs_to :product_variant
end
