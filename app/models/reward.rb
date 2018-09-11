class Reward < ApplicationRecord
  belongs_to :customer

  validates :redeemed_remote_variant_id, :referenced_remote_variant_id, presence: true
end
