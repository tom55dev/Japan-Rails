Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn

  config.breadcrumbs_logger = [:active_support_logger]
  config.send_default_pii = true
end
