class Shop < ActiveRecord::Base
  include ShopifyApp::SessionStorage

  has_many :products,       dependent: :destroy
  has_many :customers,      dependent: :destroy
  has_many :wishlists,      dependent: :destroy
  has_one  :special_offer, dependent: :destroy
end
