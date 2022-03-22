# Copied into Docker containers to change IRB configuration in staging/production
# Does not work in dev, but feel free to put this in your own ~/.irbrc

IRB.conf[:USE_MULTILINE] = false

if defined?(Rails)
  colored_env = { development: "\e[34m#{Rails.env}\e[0m", staging: "\e[33m#{Rails.env}\e[0m", production: "\e[41m\e[97m#{Rails.env}\e[0m" }
  environment = colored_env[Rails.env.to_sym]

  application_name = Rails.application.class.module_parent.name.underscore.dasherize

  IRB.conf[:PROMPT][:RAILS] = {
    PROMPT_I: "#{application_name}[#{environment}]:%03n:%i> ",
    PROMPT_N: "#{application_name}[#{environment}]:%03n:%i> ",
    PROMPT_S: "#{application_name}[#{environment}]:%03n:%i%l ",
    PROMPT_C: "#{application_name}[#{environment}]:%03n:%i* ",
    RETURN: "=> %s\n"
  }
  IRB.conf[:PROMPT_MODE] = :RAILS
end
