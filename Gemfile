source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3'
# Use MySQL2 for database
gem 'mysql2'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'jbuilder', '~> 2.5'

gem 'jquery-rails', '~> 4.3'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Rspec
  gem 'rspec-rails','~> 3.5.0'
  # binding.pry
  gem 'pry-rails'
  # factory girl/bot
  gem 'factory_bot_rails'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 4.0.1'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Database cleaner for test
  gem 'database_cleaner'
  # Integration testing gems
  gem 'rspec_junit_formatter'
end

source 'https://rails-assets.org' do
  gem 'rails-assets-bootstrap'
  gem 'rails-assets-selectize'
  gem 'rails-assets-onmount'
end

# HAML integration
gem 'haml-rails', '~> 2.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Shopify APP
gem 'shopify_app', '~> 18.1.2'

# Background Job
gem 'sidekiq', '~> 5.1'
gem 'sidekiq-failures'
gem 'redis-namespace'

# JSON serializer
gem 'jsonapi-rails'

# RACK CORS for HTTPS Allow-Access-Control-Origin
gem 'rack-cors'

# Error monitoring
gem 'sentry-ruby'
gem 'sentry-rails'

# Rest client
gem 'rest-client', '~> 2.0'
gem 'countries', '1.2.2', require: 'countries/global'

gem "emoji_regex", "~> 15.0"
