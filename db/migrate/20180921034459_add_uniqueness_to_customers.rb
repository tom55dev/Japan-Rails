class AddUniquenessToCustomers < ActiveRecord::Migration[5.1]
  def change
    add_index :customers, [:remote_id, :shop_id], unique: true
  end
end
