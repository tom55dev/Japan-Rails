class CreateSpecialOffers < ActiveRecord::Migration[5.1]
  def change
    create_table :special_offers do |t|
      t.belongs_to :shop, foreign_key: true
      t.belongs_to :product, foreign_key: true
      t.datetime :ends_at

      t.timestamps
    end
  end
end
