# Routes
Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }
  get "/authenticate", to: "authentication#index", as: :authenticate
  get "/authenticate/sign_up", to: "authentication#sign_up", as: :sign_up_authenticate

  namespace :api do
    get "auth/status", to: "auth#status"
  end
  # Main resource routes
  resources :store_sections
  resources :grocery_sections, only: [ :create ]
  resources :units
  resources :unit_conversions

  resources :groceries do
    collection do
      get :search
    end
  end

  resources :recipes do
    member do
      post :mark_completed
      post :mark_incomplete
    end
    resources :recipe_ingredients, only: [ :create, :update, :destroy ]
  end

  resources :grocery_list_items do
    member do
      post :mark_purchased
      post :mark_unpurchased
    end
    collection do
      post :bulk_update
    end
  end
end
