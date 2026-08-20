require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  # Sidekiq dashboard — chỉ người đã đăng nhập.
  authenticate :user do
    mount Sidekiq::Web => "/sidekiq"
  end

  root "dashboard#index"

  resources :trades do
    member do
      patch :status
    end
    collection do
      post :quick
    end
  end

  resources :stocks do
    member do
      patch :price
    end
    collection do
      post :refresh
    end
  end

  resources :cash_flows, except: [:show]
  resources :positions, only: :index
  resources :reports, only: :index
  resources :risk_targets, only: [:create]
  resources :watchlist_items, only: [:index, :create, :destroy] do
    member { patch :toggle }
  end
  get "tools/position-size", to: "tools#position_size", as: :position_size_tool
  get "symbols/search", to: "symbols#search"

  namespace :ai do
    resources :insights, only: [:index, :create, :show]
    resource :coach, only: :show, controller: :coach
    post "coach/message", to: "coach#message"
  end

  resource :settings, only: [:show, :update], controller: :settings
  post "settings/send-review", to: "settings#send_review", as: :send_review
  resources :trading_holidays, only: [:index, :create, :destroy]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
