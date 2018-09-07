class AddPointsCostToProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :points_cost, :integer
  end
end
