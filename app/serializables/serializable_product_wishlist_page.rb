class SerializableProductWishlistPage < JSONAPI::Serializable::Resource
  type 'wishlists'

  id { @object.token }

  attributes :name

  belongs_to :customer
end
