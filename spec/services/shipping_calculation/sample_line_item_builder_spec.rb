require 'rails_helper'

describe ShippingCalculation::SampleLineItemBuilder do
  let!(:sample_weight) { 50 }

  RSpec::Matchers.define :maintain_weight_invariant_of do |expected|
    match do |actual|
      actual.sum {|item| item.total_weight } == expected
    end

    failure_message do |actual|
      "expected that total weight of items: #{actual.sum {|item| item.total_weight }} would equal to #{expected}"
    end
  end

  context "when weight in gram is less than default item weight(50)" do
    let!(:total_weight) { 25 }
    let!(:result) { described_class.new(weight_in_grams: total_weight, sample_weight: sample_weight).call }

    it 'extracts line items of 50 g' do
      expect(result).to maintain_weight_invariant_of(total_weight)
      expect(result.count).to eq(1)
    end
  end

  context "when weight in gram is equally dividable by sample weight" do
    let!(:total_weight) { 100 }
    let!(:result) { described_class.new(weight_in_grams: total_weight, sample_weight: sample_weight).call }

    it 'returns a single item' do
      expect(result).to maintain_weight_invariant_of(total_weight)
      expect(result.count).to eq(1)
    end
  end

  context "when weight in gram is not divisable by sample weight" do
    let!(:total_weight) { 1111 }
    let!(:result) { described_class.new(weight_in_grams: total_weight, sample_weight: sample_weight).call }

    it 'returns two line items' do
      expect(result).to maintain_weight_invariant_of(total_weight)
      expect(result.count).to eq(2)
    end
  end
end