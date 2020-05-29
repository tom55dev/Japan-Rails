Rails.application.routes.draw do
  mount Sidekiq::Web => '/3ce8b877f0aebcf9fb1072a24f3ff8c9/sidekiq'

  namespace :api do
    resources :wishlists do
      member do
        post   :add_product
        delete :remove_product
      end
    end

    resources :wishlist_pages, only: [:show] do
      get :product, on: :collection
    end

    resources :products, only: [:index]

    scope '/rewards', controller: :rewards do
      post :redeem
      post :remove
    end

    scope '/loyalty_lion', controller: :loyalty_lion do
      post :customer_updated
    end

    scope '/contact', controller: :contact do
      post :create_ticket
    end

    resource :shipping_calculation_requests, only: [:create]
  end

  scope Rails.application.secrets.encrypted_path.to_s do
    resources :home, path: '/', only: [:index]
    resource :special_offer, only: [:edit, :update] do
      get :search
    end
  end

  get 'update_order_shipping', to: 'order_shipping#new'

  root to: redirect('http://japanhaul.com')

  post '/api/webhooks/:type', to: 'api/webhooks#receive', as: :api_webhook

  mount ShopifyApp::Engine, at: Rails.application.secrets.encrypted_path.to_s

  get '*path' => redirect('http://japanhaul.com')
end
