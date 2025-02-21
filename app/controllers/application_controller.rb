class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session, if: -> { request.format.json? }
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper ReactHelper

  def favicon
    send_file Rails.root.join("app", "assets", "images", "favicon.svg"),
              type: "image/svg+xml",
              disposition: "inline"
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :email, :password, :password_confirmation ])
  end

  def after_sign_in_path_for(resource)
    groceries_path
  end

  def after_sign_up_path_for(resource)
    groceries_path(reload: true)
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
