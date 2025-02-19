# Routes
Rails.application.routes.draw do
  get "grocery_list_items/index"
  get "grocery_list_items/create"
  get "grocery_list_items/update"
  get "grocery_list_items/destroy"
  get "recipe_ingredients/create"
  get "recipe_ingredients/update"
  get "recipe_ingredients/destroy"
  get "recipes/index"
  get "recipes/show"
  get "recipes/create"
  get "recipes/update"
  get "recipes/destroy"
  get "unit_conversions/index"
  get "unit_conversions/create"
  get "unit_conversions/update"
  get "unit_conversions/destroy"
  root "home#index"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }
  get "/authenticate", to: "authentication#index", as: :authenticate
  namespace :api do
    get "auth/status", to: "auth#status"
  end
  # Main resource routes
  resources :store_sections
  resources :grocery_sections
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
