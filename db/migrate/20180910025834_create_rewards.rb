class CreateRewards < ActiveRecord::Migration[5.1]
  def change
    create_table :rewards do |t|
      t.belongs_to :customer, foreign_key: true
      t.string     :redeemed_remote_variant_id
      t.string     :referenced_remote_variant_id

      t.timestamps
    end

    add_index :rewards, :redeemed_remote_variant_id
    add_index :rewards, :referenced_remote_variant_id
  end
end
