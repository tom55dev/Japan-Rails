class AddProductIdToWishlistItems < ActiveRecord::Migration[5.1]
  def up
    add_reference :wishlist_items, :product, foreign_key: true

    remove_column :wishlist_items, :shopify_product_id
    remove_column :wishlist_items, :shopify_variant_id
  end

  def down
    remove_reference :wishlist_items, :product, foreign_key: true

    add_column :wishlist_items, :shopify_product_id, :string
    add_column :wishlist_items, :shopify_variant_id, :string
  end
end
