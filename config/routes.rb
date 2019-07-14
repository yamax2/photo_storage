require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root 'pages#show'

  resources :pages, only: :show, path: 'rubrics' do
    resources :photos, only: :show
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

    resources :rubrics, except: :show
    namespace :rubrics do
      resources :positions, only: %i[index create]
    end

    resources :photos, only: :create
  end

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      namespace :admin do
        resources :rubrics, only: :index
      end
    end
  end
end
