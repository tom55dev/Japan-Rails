class SerializableWishlist < JSONAPI::Serializable::Resource
  type 'wishlists'

  id { @object.token }

  attributes :name, :wishlist_type

  attribute :customer_id do
    @object.shopify_customer_id
  end

  attribute :product_ids do
    @object.products.map(&:remote_id)
  end
end
