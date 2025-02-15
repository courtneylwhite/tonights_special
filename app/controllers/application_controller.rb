class ApplicationController < ActionController::Base
  # Ensure Devise can find the correct resources
  before_action :configure_permitted_parameters, if: :devise_controller?

  # protect_from_forgery with: :exception
  # skip_before_action :verify_authenticity_token
  # before_action :configure_permitted_parameters, if: :devise_controller?
  helper ReactHelper

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :password_confirmation])
  end

  # Optional: Customize redirect paths
  def after_sign_in_path_for(resource)
    root_path # or dashboard_path, etc.
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end