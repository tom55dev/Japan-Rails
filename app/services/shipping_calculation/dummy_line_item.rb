module ShippingCalculation
  class DummyLineItem
    DEFAULT_PRICE    = 1
    DEFAULT_QUANTITY = 1

    attr_accessor :grams, :price, :quantity

    def initialize(grams:, price: DEFAULT_PRICE, quantity: DEFAULT_QUANTITY)
      @grams    = grams
      @price    = price
      @quantity = quantity
    end

    def total_weight
      grams * quantity
    end

    def to_h
      {
        quantity: quantity,
        grams:    grams,
        price:    price,
      }
    end
  end
end