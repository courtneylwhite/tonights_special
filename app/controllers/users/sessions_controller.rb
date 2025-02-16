class Users::SessionsController < Devise::SessionsController
  # Optional: Add custom logic for sign in
  def create
    super do |resource|
      # Add any custom logic after successful sign in
      # For example, logging, tracking, etc.
    end
  end
end
