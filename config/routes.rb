Rails.application.routes.draw do
  root 'pages#index'

  namespace :admin do
    root 'dashboard#index'
  end
end
