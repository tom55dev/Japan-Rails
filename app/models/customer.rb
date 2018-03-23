class Customer < ApplicationRecord
  belongs_to :shop

  validates :remote_id, presence: true, uniqueness: true
end
