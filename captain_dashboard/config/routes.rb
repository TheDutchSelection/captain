Rails.application.routes.draw do
  root 'home#index'

  devise_for :users, controllers: { sessions: 'sessions' }, :skip => [:passwords, :registration]

  get 'etcd', to: 'etcd#index'

  resources :apps
  put 'apps/:id/:zone_id/:key/:value', to: 'apps#set_key_in_zone', as: 'key_in_zone_app'

  resources :zones

  # Admins only
  resources :users do
    match 'password', on: :member, via: [:get, :put, :patch]
  end
end
