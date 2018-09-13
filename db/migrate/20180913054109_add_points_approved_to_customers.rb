class AddPointsApprovedToCustomers < ActiveRecord::Migration[5.1]
  def change
    add_column :customers, :points_approved, :integer
  end
end
