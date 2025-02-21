class AuthenticationController < ApplicationController
  before_action :redirect_if_authenticated
  helper Devise::Controllers::Helpers
  helper_method :resource_name, :resource_class, :devise_mapping
  def index
    @resource = resource_class.new
  end

  def sign_up
    @resource = resource_class.new
  end

  # These methods are required to make Devise helpers work
  def resource_name
    :user
  end

  def resource_class
    User
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  private

  def redirect_if_authenticated
    if user_signed_in?
      redirect_to root_path, notice: "You are already logged in."
    end
  end
end
