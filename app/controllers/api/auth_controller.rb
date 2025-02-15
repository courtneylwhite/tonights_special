# app/controllers/api/auth_controller.rb
module Api
  class AuthController < ApplicationController
    def status
      if user_signed_in?
        render json: {
          user: {
            id: current_user.id,
            email: current_user.email
            # Add any other user attributes you want to expose
          },
          authenticated: true
        }
      else
        render json: { authenticated: false, user: nil }
      end
    end
  end
end
