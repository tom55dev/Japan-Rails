require 'rails_helper'

describe CustomerFinder do
  let!(:shop) { create :shop }
  let!(:customer_id) { '123456' }

  let!(:customer_finder) { CustomerFinder.new(shop, customer_id) }

  context 'when no customer exists' do
    let!(:mock_customer) { instance_double(Customer) }

    it 'syncs the customer' do
      expect(CustomerSync).to receive(:new).and_return -> { mock_customer }

      expect(customer_finder.call).to eq mock_customer
    end
  end

  context 'when a customer exists' do
    let!(:customer) { create :customer, remote_id: customer_id, shop: shop }

    it 'returns the customer' do
      expect(CustomerSync).not_to receive(:new)

      expect(customer_finder.call).to eq customer
    end
  end
end
