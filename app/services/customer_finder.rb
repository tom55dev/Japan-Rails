class CustomerFinder
  attr_reader :shop, :customer_id

  def initialize(shop, customer_id)
    @shop = shop
    @customer_id = customer_id
  end

  def call
    existing_customer || sync_customer
  end

  private

  def existing_customer
    shop.customers.find_by(remote_id: customer_id)
  end

  def sync_customer
    CustomerSync.new(shop, customer_id: customer_id).call
  end
end
