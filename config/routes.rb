# Routes
Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }
  get "/authenticate", to: "authentication#index", as: :authenticate
  resources :groceries
  namespace :api do
    get "auth/status", to: "auth#status"
  end
end
