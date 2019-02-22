module ShippingCalculation
  class SampleLineItemBuilder
    DEFAULT_ITEM_WEIGHT = 50

    attr_accessor :weight_in_grams, :sample_weight

    def initialize(weight_in_grams:, sample_weight: DEFAULT_ITEM_WEIGHT)
      @weight_in_grams = weight_in_grams
      @sample_weight = sample_weight
    end

    def call
      [full_weight_item, partial_weight_item].compact
    end

    private

    def full_weight_item
      box_count = weight_in_grams / sample_weight
      if box_count == 0
        nil
      else
        build_item(sample_weight, box_count)
      end
    end

    def partial_weight_item
      remaining_weight = weight_in_grams % sample_weight
      if remaining_weight == 0
        nil
      else
        build_item(remaining_weight, 1)
      end
    end

    def build_item(weight, qty)
      ShippingCalculation::DummyLineItem.new(grams: weight, quantity: qty)
    end

  end
end