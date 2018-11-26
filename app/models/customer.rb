class Customer < ApplicationRecord
  belongs_to :shop
  has_many :rewards, dependent: :destroy

  validates :remote_id, presence: true, uniqueness: { scope: :shop_id }

  before_validation :strip_emoji

  def initials
    [
      first_name.to_s[0].try(:upcase),
      last_name.to_s[0].try(:upcase)
    ].compact.join
  end

  private

  def strip_emoji
    self.first_name = StripEmoji.replace(first_name) if first_name?
    self.last_name = StripEmoji.replace(last_name) if last_name?
  end
end
