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
  end

  scope Rails.application.secrets.encrypted_path do
    resources :home, path: '/', only: [:index]
    resource :special_offer, only: [:edit, :update] do
      get :search
    end
  end

  root to: redirect('http://japanhaul.com')

  mount ShopifyApp::Engine, at: Rails.application.secrets.encrypted_path
end
