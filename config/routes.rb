Rails.application.routes.draw do\
  root "home#index"
  resources :accounts, except: :show do
    resources :trades
    get 'positions' => 'positions#index', as: 'positions'
    resources :gain_losses, only: :index
  end
  resources :securities, except: :show
  resources :currencies, except: :show

end
