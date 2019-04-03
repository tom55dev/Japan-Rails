namespace :custom do
  task :check_secrets_defined do
    def flatten_secrets(hash, prefix = '')
      hash.reduce({}) do |flattened_hash, (name, value)|
        if value.is_a?(Hash)
          flattened_hash.merge(flatten_secrets(value, "#{prefix}#{name}."))
        else
          flattened_hash.merge("#{prefix}#{name}" => value)
        end
      end
    end

    on roles(:app) do
      within current_path do
        actual_secrets = YAML.load(capture(:cat, "#{release_path}/config/secrets.yml"))[fetch(:stage).to_s]
        expected_secrets = YAML.load(capture(:cat, "#{release_path}/config/secrets.template.yml"))['<environment>']

        missing_keys = flatten_secrets(expected_secrets).keys - flatten_secrets(actual_secrets).keys

        if missing_keys.any?
          puts
          puts "\e[31mCannot deploy: secrets.yml does not match the template"
          puts '------------------------------------------------------'
          puts 'Missing keys:'
          missing_keys.each { |key| puts "- #{key}" }
          puts "\e[0m"

          raise 'Please add the above keys to secrets'
        end
      end
    end
  end
end
