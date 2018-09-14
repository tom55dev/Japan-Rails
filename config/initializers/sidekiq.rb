redis_opt = {
  url: 'redis://localhost:6379/0', namespace: "sidekiq_japanhaul-rails_#{Rails.env}"
}

Sidekiq.configure_server do |config|
  config.redis = redis_opt
end

Sidekiq.configure_client do |config|
  config.redis = redis_opt
end
