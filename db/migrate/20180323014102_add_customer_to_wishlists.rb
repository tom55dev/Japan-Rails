class AddCustomerToWishlists < ActiveRecord::Migration[5.1]
  def change
    add_reference :wishlists, :customer, foreign_key: true

    remove_column :wishlists, :shopify_customer_id, :string
  end
end
