class ApiController < ActionController::API
  before_action :valid_request?

  protected

  def valid_request?
    whitelisted = Rails.application.secrets.whitelisted_domains

    if !Rails.env.development? ||
       current_shop.blank? ||
       (request.origin.present? && whitelisted.exclude?(URI.parse(request.origin).host))
      render json: { msg: 'Sorry, you don\'t have any access to this website.' }, status: 403
    end
  end

  def current_shop
    @current_shop ||= Shop.find_by(shopify_domain: params[:shop])
  end
end
