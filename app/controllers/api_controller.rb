class ApiController < ActionController::API
  before_action :set_access_control_headers
  before_action :valid_request?

  protected

  def valid_request?
    whitelisted = Rails.application.secrets.whitelisted_domains

    unless request.origin.present? && whitelisted.include?(URI.parse(request.origin).host)
      render json: { msg: 'Sorry, you don\'t have any access to this websote.' }, status: 403
    end
  end

  def set_access_controller_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end
end
