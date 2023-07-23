Rails.application.routes.draw do


  root "home#index"
  resources :accounts, except: :show do
      resources :transactions
  end
  resources :securities, except: :show
  resources :currencies, except: :show
end
