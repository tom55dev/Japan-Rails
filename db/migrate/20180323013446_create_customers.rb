class CreateCustomers < ActiveRecord::Migration[5.1]
  def change
    create_table :customers do |t|
      t.belongs_to :shop, foreign_key: true
      t.string :remote_id
      t.string :email
      t.string :first_name
      t.string :last_name
      t.integer :orders_count

      t.timestamps
    end

    add_index :customers, :remote_id
  end
end
