class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  def create
    # Add additional validation or reCAPTCHA here if needed
    super
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email])
  end

  # Optional: Add rate limiting
  def create
    # Implement rate limiting logic here
    # You might want to use a gem like rack-attack for this
    super
  end
end