class SerializableWishlist < JSONAPI::Serializable::Resource
  type 'wishlists'

  id { @object.token }
  customer_id { @object.shopify_customer_id }

  attributes :name, :wishlist_type, :customer_id

  has_many :wishlist_items
end
