# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root 'pages#show'

  resources :pages, only: :show, path: 'rubrics' do
    resources :photos, only: :show
  end

  namespace :proxy do
    get '*storage_path' => 'dev#null', as: :object
    get 'previews/*storage_path' => 'dev#null', as: :object_preview
    get 'reload' => 'dev#null', as: :reload
  end

  namespace :admin do
    mount Sidekiq::Web => '/sidekiq'

    root 'dashboard#index'

    namespace :yandex do
      resources :tokens, only: %i[index edit update destroy] do
        member do
          get :refresh
        end
      end

      resource :verification_code, only: :show
    end

    resources :rubrics, except: :show do
      resources :tracks, except: %i[create new]
    end

    namespace :rubrics do
      resources :positions, only: %i[index create]
    end

    resources :photos, only: %i[edit update]
    resources :cart, only: %i[index update]
  end

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      resources :rubrics, only: :show do
        resources :tracks, only: :index

        member do
          get :summary
        end
      end

      namespace :admin do
        resources :uploads, only: :create
        resources :rubrics, only: %i[index update]

        namespace :yandex do
          resources :tokens, only: %i[index show]
        end

        namespace :cart do
          resources :rubrics, only: :index
        end

        namespace :photos do
          post   ':photo_id/cart' => 'cart#create', as: :cart
          delete ':photo_id/cart' => 'cart#destroy', as: nil
        end
      end
    end
  end
end
