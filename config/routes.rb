Rails.application.routes.draw do
  root "home#index"

  # Devise routes
  devise_for :users,
             controllers: {
               registrations: 'users/registrations'
             },
             defaults: { format: :json }

  # Add an endpoint to check auth status
  get '/api/auth/status', to: 'auth#status'

  # get '/welcome', to: 'welcome#index'
  # get '/signin', to: 'welcome#index'
  # get '/signup', to: 'welcome#index'


  # get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")

end
