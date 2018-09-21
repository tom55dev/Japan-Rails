class AddRefundedAtToRewards < ActiveRecord::Migration[5.1]
  def change
    add_column :rewards, :refunded_at, :datetime
  end
end
