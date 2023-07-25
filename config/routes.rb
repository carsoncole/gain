Rails.application.routes.draw do\
  root "home#index"
  resources :accounts, except: :show do
      resources :transactions
      get 'positions' => 'positions#index', as: 'positions'
  end
  resources :securities, except: :show
  resources :currencies, except: :show
end
