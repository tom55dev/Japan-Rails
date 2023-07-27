class ShopifyController < ShopifyApp::AuthenticatedController
  helper_method :current_shop

  protected

  def current_shop
    @current_shop ||= Shop.find_by(shopify_domain: @current_shop_session.domain)
  end
end
