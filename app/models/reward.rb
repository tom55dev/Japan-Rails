class Reward < ApplicationRecord
  belongs_to :customer
  belongs_to :product_variant, foreign_key: :redeemed_remote_variant_id, primary_key: :remote_id

  validates :redeemed_remote_variant_id, :referenced_remote_variant_id, presence: true
end
