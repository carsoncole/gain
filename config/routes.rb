Rails.application.routes.draw do
  root "home#index"
  resources :accounts
  resources :securities

  get 'settings/index', as: 'settings'
end
