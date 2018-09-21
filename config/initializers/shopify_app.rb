ShopifyApp.configure do |config|
  website_url = File.join(Rails.application.secrets.website_url.to_s, Rails.application.secrets.encrypted_path.to_s)

  config.application_name = 'JapanHaul App'
  config.api_key = Rails.application.secrets.shopify_api_key
  config.secret= Rails.application.secrets.shopify_secret
  config.scope = 'read_orders, read_products, read_customers, write_customers, write_products, write_script_tags'
  config.embedded_app = true
  config.after_authenticate_job = false
  config.session_repository = Shop

  config.webhook_jobs_namespace = 'shopify'

  config.root_url = Rails.application.secrets.encrypted_path

  # Webhooks
  webhook_url = File.join(Rails.application.secrets.website_url.to_s, 'api/webhooks')
  config.webhooks = [
    { topic: 'customers/create', address: File.join(webhook_url, 'customers_sync') },
    { topic: 'customers/update', address: File.join(webhook_url, 'customers_sync') },
    { topic: 'products/create', address: File.join(webhook_url, 'products_create') },
    { topic: 'products/update', address: File.join(webhook_url, 'products_update') },
    { topic: 'products/delete', address: File.join(webhook_url, 'products_delete') },
    { topic: 'orders/paid', address: File.join(webhook_url, 'orders_paid') },
    { topic: 'refunds/create', address: File.join(webhook_url, 'refunds_create') }
  ]

  config.after_authenticate_job = { job: Shopify::ShopSyncJob }
end
