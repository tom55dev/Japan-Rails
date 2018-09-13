namespace :loyalty_lion do
  desc 'Updates LoyaltyLion with the current site as the only webhook endpoint'
  task :refresh_webhook, [:shop_domain] => :environment do |_, args|
    shop_domain = args[:shop_domain]
    shop_domain ||= Shop.first.shopify_domain if Shop.count == 1

    raise 'Shop domain must be specified' unless shop_domain.present?

    delete_all_webhooks
    create_webhook(shop_domain)
  end

  desc 'Deletes all webhooks from LoyaltyLion'
  task delete_webhooks: :environment do |_, args|
    delete_all_webhooks
  end

  def create_webhook(shop_domain)
    response = RestClient.post(
      webhooks_api_url,
      {
        webhook: {
          topic: 'customers/update',
          address: "#{Rails.application.secrets.website_url}/api/loyalty_lion/customer_updated?shop=#{shop_domain}"
        }
      }.to_json,
      content_type: :json
    )

    data = JSON.parse(response.body)
    puts "Created webhook ##{data['webhook']['id']}: #{data['webhook']['address']}"
  end

  def delete_all_webhooks
    response = RestClient.get(webhooks_api_url)
    listing = JSON.parse(response.body)

    listing['webhooks'].each do |webhook|
      RestClient.delete("#{webhooks_api_url}/#{webhook['id']}")
      puts "Deleted webhook ##{webhook['id']}: #{webhook['address']}"
    end
  end

  def credentials
    [
      Rails.application.secrets.loyalty_lion_api_token,
      Rails.application.secrets.loyalty_lion_api_secret
    ].join(':')
  end

  def webhooks_api_url
    "https://#{credentials}@#{Rails.application.secrets.loyalty_lion_api_url}/v2/webhooks"
  end
end
