class Users::RegistrationsController < Devise::RegistrationsController
  # Optional: Add custom logic for sign up
  def create
    super do |resource|
      # Add any custom logic after successful registration
      # For example, welcome email, logging, etc.
    end
  end

  # Optional: Customize permitted parameters
  protected

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
