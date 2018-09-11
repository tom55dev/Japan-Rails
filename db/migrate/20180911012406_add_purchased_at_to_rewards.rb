class AddPurchasedAtToRewards < ActiveRecord::Migration[5.1]
  def change
    add_column :rewards, :purchased_at, :datetime

    add_index :rewards, :purchased_at
  end
end
