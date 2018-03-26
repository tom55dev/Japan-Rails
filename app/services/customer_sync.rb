class CustomerSync
  attr_reader :shop, :customer

  def initialize(shop, customer_id)
    @shop = shop

    shop.with_shopify_session do
      @customer = ShopifyAPI::Customer.find(customer_id)
    end
  end

  def call
    if existing_customer
      existing_customer.update!(customer_params)
      existing_customer
    else
      shop.customers.create!(customer_params)
    end
  end

  private

  def existing_customer
    @existing_customer ||= shop.customers.find_by(remote_id: customer.id)
  end

  def customer_params
    {
      remote_id:    customer.id,
      email:        customer.email,
      first_name:   customer.first_name,
      last_name:    customer.last_name,
      orders_count: customer.orders_count
    }
  end
end
