class SpecialOfferSyncJob < ApplicationJob
  attr_reader :special_offer

  queue_as :shopify_sync

  def perform(special_offer_id)
    @special_offer = SpecialOffer.find(special_offer_id)

    special_offer.shop.with_shopify_session do
      sync!
    end
  end

  private

  def sync!
    if special_offer.metafield_id.blank?
      create_metafield!
    else
      update_metafield!
    end
  end

  def key_and_value
    "#{special_offer.product.handle}:#{special_offer.ends_at.to_i}"
  end

  def create_metafield!
    metafield = ShopifyAPI::Metafield.create({
      namespace: 'japanhaul',
      key: 'special_offer',
      value: key_and_value,
      value_type: 'string'
    })
    special_offer.update(metafield_id: metafield.id)
  end

  def update_metafield!
    metafield = ShopifyAPI::Metafield.find(special_offer.metafield_id)
    metafield.value = key_and_value
    metafield.save
  end
end
