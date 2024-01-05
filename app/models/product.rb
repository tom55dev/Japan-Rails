class Product < ApplicationRecord
  belongs_to :shop

  has_many :product_variants, dependent: :destroy

  validates :remote_id, uniqueness: { scope: :shop_id, case_sensitive: true }

  before_save :sanitize_emoji

  def body_html_with_emoji
    body_html.gsub(/\\u\{([0-9a-fA-F,]+)\}/) do |match|
      codepoints = Regexp.last_match(1).split(',').map { |hex| hex.to_i(16) }
      codepoints.pack('U*')
    end
  end

  private

  def sanitize_emoji
    self.body_html = body_html.gsub(EmojiRegex::Regex) do |emoji|
      "\\u{#{emoji.codepoints.map { |c| c.to_s(16) }.join(',')}}"
    end
  end
end
