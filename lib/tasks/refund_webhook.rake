namespace :refund_webhook do
  desc 'Creates a webhook for refunds'
  task create: :environment do
    webhook_url = File.join(Rails.application.credentials.website_url.to_s, 'api/webhooks')

    Shop.all.each do |shop|
      shop.with_shopify_session do
        ShopifyAPI::Webhook.create({ topic: 'refunds/create', address: File.join(webhook_url, 'refunds_create') })
      end
    end
  end
end
