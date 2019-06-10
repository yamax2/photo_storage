require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root 'pages#index'

  namespace :admin do
    mount Sidekiq::Web => '/sidekiq'

    root 'dashboard#index'
  end
end
