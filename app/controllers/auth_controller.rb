class AuthController < ApplicationController
  def status
    if user_signed_in?
      render json: {
        user: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
      }
    else
      render json: { user: nil }
    end
  end
end