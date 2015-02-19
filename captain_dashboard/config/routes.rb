Rails.application.routes.draw do
  root 'home#index'

  devise_for :users, controllers: { sessions: 'sessions' }, :skip => [:passwords, :registration]

  get 'etcd', to: 'etcd#index'

  resources :zones

  # Admins only
  resources :users do
    match 'password', on: :member, via: [:get, :put, :patch]
  end
end
