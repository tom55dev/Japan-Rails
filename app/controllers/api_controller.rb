class ApiController < ActionController::API
  before_action :valid_request?

  protected

  def valid_request?
    whitelisted = Rails.application.secrets.whitelisted_domains

    unless request.origin.present? && whitelisted.include?(URI.parse(request.origin).host)
      render json: { msg: 'Sorry, you don\'t have any access to this websote.' }, status: 403
    end
  end
end
