class Users::SessionsController < Devise::SessionsController
  # Optional: Add custom logic for sign in
  def create
    super do |resource|
      # Add any custom logic after successful sign in
      # For example, logging, tracking, etc.
    end
  end

  # Optional: Customize after sign in path
  def after_sign_in_path_for(resource)
    pantry_path(resource)
  end
end
