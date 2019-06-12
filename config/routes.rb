require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root 'pages#index'

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

    resources :rubrics
  end
end
