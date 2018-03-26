class SerializableCustomer < JSONAPI::Serializable::Resource
  type 'customers'

  id { @object.remote_id.to_i }

  attributes :email, :first_name, :last_name, :initials
end
