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

    scope '/contact', controller: :contact do
      post :create_ticket
    end

    resource :shipping_calculation_requests, only: [:create]
  end

  scope Rails.application.credentials.encrypted_path.to_s do
    resources :home, path: '/', only: [:index]
    resource :special_offer, only: [:edit, :update] do
      get :search
    end
  end

  get 'update_order_shipping', to: 'order_shipping#new'

  if Rails.env.production?
    root to: redirect('https://japanhaul.com')
  else
    root to: 'home#index'
  end

  post '/api/webhooks/:type', to: 'api/webhooks#receive', as: :api_webhook

  mount ShopifyApp::Engine, at: Rails.application.credentials.encrypted_path.to_s

  if Rails.env.production?
    get '*path' => redirect('https://japanhaul.com')
  else
    get '*path' => 'home#index'
  end
end
