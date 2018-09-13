class WishlistCreator
  include ActiveModel::Model

  attr_accessor :shop, :form_type, :product_ids, :name, :wishlist_type, :customer_id

  validates :shop, :form_type, :customer_id, presence: true
  validates :product_ids, presence: true, if: :auto?
  validates :name, :wishlist_type, presence: true, if: :manual?

  def call
    valid? && persist!
  end

  private

  def persist!
    begin
      ActiveRecord::Base.transaction do
        wishlist = shop.wishlists.create!(wishlist_params)
        wishlist.wishlist_items.create!(wishlist_items_params) if auto?

        wishlist
      end
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
    end
  end

  def wishlist_params
    {
      name: auto? ? products.first.title : name,
      wishlist_type: auto? ? 'private' : wishlist_type,
      customer: customer
    }
  end

  def wishlist_items_params
    products.map do |product|
      { product_id: product.id }
    end
  end

  def products
    @products ||= Product.where(remote_id: product_ids)
  end

  def auto?
    form_type == 'auto'
  end

  def manual?
    form_type == 'manual'
  end

  def customer
    CustomerSync.new(shop, customer_id: customer_id).call
  end
end
