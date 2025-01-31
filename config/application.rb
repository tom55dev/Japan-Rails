require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JapanhaulRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.active_job.queue_adapter = :sidekiq

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins *Rails.application.credentials.whitelisted_domains
        resource '*', :headers => :any, :methods => [:get, :post, :delete, :put, :options], :expose => ['Authorization'], credentials: true
      end
    end

    config.time_zone = 'Tokyo'

    # This will rotate to a maximum of 5 log file with
    # a maximum size of 3 gigabytes each, (production: 15GB / 50GB)
    config.logger = ActiveSupport::Logger.new(config.paths['log'].first, 4, 3.gigabytes)
  end
end
