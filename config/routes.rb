Rails.application.routes.draw do
  get "authentication/index"
  root 'home#index'
  get '/favicon.ico', to: 'application#favicon'

  # Custom page to show authentication options
  get '/authenticate', to: 'authentication#index'

  # Devise routes with custom controllers
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  get "up" => "rails/health#show", as: :rails_health_check
end
