class AuthenticationController < ApplicationController
  # Optional: Redirect if already logged in
  before_action :redirect_if_authenticated

  def index
    # This action will render the custom authentication page
    # It can display both login and registration forms
    @user = User.new
  end

  private

  def redirect_if_authenticated
    if user_signed_in?
      redirect_to root_path, notice: "You are already logged in."
    end
  end
end