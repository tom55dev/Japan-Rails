class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def current_shop
    @current_shop ||= Shop.find_by(shopify_domain: @shop_session.url)
  end
end
