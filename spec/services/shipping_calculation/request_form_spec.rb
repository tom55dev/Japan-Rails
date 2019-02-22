require 'rails_helper'

describe ShippingCalculation::RequestForm do
  let!(:client) { double }
  let!(:line_item) { instance_double(ShippingCalculation::DummyLineItem) }
  let!(:line_item_builder) { double(call: [line_item]) }

  before do
    allow(ShippingCalculation::OMSApiClient).to receive(:new).and_return(client)
  end

  context 'when requested with grams unit' do
    let!(:request_params) {
      {
        country: 'United States',
        weight_unit: 'grams',
        weight_value: 1
      }
    }

    it 'calls OMS api with correct params' do
      form = described_class.new(request_params)
      expect(ShippingCalculation::SampleLineItemBuilder).to receive(:new).with(weight_in_grams: 1).and_return(line_item_builder)
      expect(client).to receive(:calculate_shipping).with(
        'US',
        [line_item]
      ).and_return({'rates' => []})
      form.create
    end
  end

  context 'when requested with pounds unit' do
    let!(:request_params) {
      {
        country: 'United States',
        weight_unit: 'pounds',
        weight_value: 1
      }
    }

    it 'calls OMS api with correct params' do
      form = described_class.new(request_params)
      # 1 pound = 453.592 grams
      expect(ShippingCalculation::SampleLineItemBuilder).to receive(:new).with(weight_in_grams: 453.592).and_return(line_item_builder)
      expect(client).to receive(:calculate_shipping).with(
        'US',
        [line_item]
      ).and_return({'rates' => []})
      form.create
    end
  end

  context 'when oms api returns error' do
    let!(:request_params) {
      {
        country: 'United States',
        weight_unit: 'pounds',
        weight_value: 1
      }
    }

    it 'adds a nice base error' do
      form = described_class.new(request_params)
      # 1 pound = 453.592 grams
      allow(ShippingCalculation::SampleLineItemBuilder).to receive(:new).and_return(line_item_builder)
      allow(client).to receive(:calculate_shipping).and_raise(ShippingCalculation::OMSApiClient::Error)
      form.create
      expect(form.errors[:base]).to be_present
    end
  end
end
