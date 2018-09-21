namespace :refund_webhook do
  desc 'Creates a webhook for refunds'
  task create: :environment do
    website_url = File.join(Rails.application.secrets.website_url.to_s, Rails.application.secrets.encrypted_path.to_s)

    Shop.all.each do |shop|
      shop.with_shopify_session do
        ShopifyAPI::Webhook.create({ topic: 'refunds/create', address: File.join(webhook_url, 'refunds_create') })
      end
    end
  end
end
