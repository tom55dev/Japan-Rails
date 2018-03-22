role :web, 'deployer@159.65.242.196'
role :db,  'deployer@159.65.242.196'
role :app, 'deployer@159.65.242.196'

set :rail_env, :staging

set :rvm_ruby_version, '2.3.0@japanhaul-rails'
