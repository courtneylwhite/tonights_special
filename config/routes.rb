# Routes
Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

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

  resources :grocery_sections, only: [ :index ]

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

  mount ActionMailbox::Engine => "/rails/action_mailbox"
end
