class ShopifyController < ShopifyApp::AuthenticatedController
  helper_method :current_shop

  protected

  def current_shop
    @current_shop ||= Shop.find_by(shopify_domain: @shop_session.url)
  end
end
