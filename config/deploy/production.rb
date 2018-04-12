role :web, 'deployer@104.131.92.85'
role :db,  'deployer@104.131.92.85'
role :app, 'deployer@104.131.92.85'

set :rail_env, :production

set :rvm_ruby_version, '2.3.1@japanhaul-rails'
