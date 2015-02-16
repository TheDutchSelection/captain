Rails.application.routes.draw do
  root 'home#index'

  get 'etcd', to: 'etcd#index'

  resources :zones, except: [:show]
end
