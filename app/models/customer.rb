class Customer < ApplicationRecord
  belongs_to :shop

  validates :remote_id, presence: true, uniqueness: true

  def initials
    [
      first_name.to_s[0].try(:upcase),
      last_name.to_s[0].try(:upcase)
    ].compact.join
  end
end
