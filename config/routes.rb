Rails.application.routes.draw do

  root "home#index"
  resources :accounts
  resources :securities
  resources :currencies
end
