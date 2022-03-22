class SyncAllProducts
  CYCLE = 0.5

  attr_reader :shop

  def initialize(shop)
    @shop = shop

    access = ShopifyAPI::Session.new(domain: shop.shopify_domain, token: shop.shopify_token, api_version: ShopifyApp.configuration.api_version)

    ShopifyAPI::Base.activate_session(access)
  end

  def call
    shop.with_shopify_session do
      execute!
    end
  end

  private

  def execute!
    # Initializing
    start_time = Time.now

    products = ShopifyAPI::Product.find(:all, params: { limit: 250 })
    first = true

    loop do
      if !first
        first = false
        stop_time = Time.now
        puts "Last batch processing started at #{start_time.strftime('%I:%M:%S%p')}"
        puts "The time is now #{stop_time.strftime('%I:%M:%S%p')}"

        processing_duration = stop_time - start_time
        puts "The processing lasted #{processing_duration.to_i} seconds."
        wait_time = (CYCLE - processing_duration).ceil
        puts "We have to wait #{wait_time} seconds then we will resume."
        sleep wait_time if wait_time > 0
        start_time = Time.now
      end

      sync_products(products)

      if products.next_page?
        products = products.fetch_next_page
      else
        break
      end
    end
  end

  def sync_products(products)
    products.each do |product|
      begin
        model = ProductSync.new(shop, product).call

        product.variants.each do |variant|
          ProductVariantSync.new(model, variant).call
        end
      rescue ActiveResource::ConnectionError, ActiveResource::ClientError, ActiveResource::ServerError => e
        if e.response.code.to_s == '429' || e.response.code.to_s == '503'
          puts "Muted for 10 seconds to handle #{e.response.code} response..."
          sleep 10
          retry
        else
          raise e
        end
      end
    end
  end

  def total_pages_count
    (total_product_count / 250.0).ceil
  end

  def total_product_count
    @total_product_count ||= ShopifyAPI::Product.count
  end
end
