Rails.application.routes.draw do\
  root "home#welcome"

  resources :passwords,
    controller: 'clearance/passwords',
    only: [:create, :new]

  resource :session,
    controller: 'clearance/sessions',
    only: [:create]

  resources :users,
    controller: 'clearance/users',
    only: Clearance.configuration.user_actions do
      resource :password,
        controller: 'clearance/passwords',
        only: [:edit, :update]
    end

  get '/sign_in' => 'clearance/sessions#new', as: 'sign_in'
  delete '/sign_out' => 'clearance/sessions#destroy', as: 'sign_out'

  if Clearance.configuration.allow_sign_up?
    get '/sign_up' => 'clearance/users#new', as: 'sign_up'
  end

  resources :accounts, except: :show do
    resources :trades
    get 'schedule-d' => 'gain_losses#schedule_d', as: 'schedule_d'
    resources :lots, only: :index
    get 'positions' => 'positions#index', as: 'positions'
    resources :gain_losses, only: :index
  end
  resources :securities, except: :show
  resources :currencies, except: :show



end
