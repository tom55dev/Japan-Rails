class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage

  has_many :products, dependent: :destroy
  has_many :product_variants, through: :products
  has_many :customers, dependent: :destroy
  has_many :wishlists, dependent: :destroy
  has_one  :special_offer, dependent: :destroy

  def api_version
    ShopifyApp.configuration.api_version
  end
end
