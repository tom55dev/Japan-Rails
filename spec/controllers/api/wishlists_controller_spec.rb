require 'rails_helper'

describe Api::WishlistsController do
  describe 'POST #create' do
    context 'when certain condition is met' do
      let(:valid_wishlist_params) do
        {
          customer_id: 7034366034086,
          form_type: 'auto',
          product_ids: [7763739869350, 7760647028902],
          shop: 'japanhaul-staging.myshopify.com'
        }
      end

      it 'returns an empty json response with status :ok' do
        post :create, params: valid_wishlist_params

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
        expect(response.body).to eq('[]')
      end
    end
  end
end
