class SerializableWishlistItem < JSONAPI::Serializable::Resource
  type 'wishlist_items'

  attribute :product_id do
    @object.product.remote_id
  end
end
