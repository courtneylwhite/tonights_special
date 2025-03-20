# spec/support/login_helper.rb

# This is a fix for Devise controller tests that addresses the
# "Could not find a valid mapping for #<User..." error
module LoginHelper
  # We need to make absolutely sure the controller has access to @request
  # before attempting to set any mappings
  def login(user)
    # Ensure mapping is set up first
    setup_mapping
    # Then sign in
    sign_in user
    user
  end

  # Setup Devise mapping explicitly
  def setup_mapping
    # Make sure we have a controller and request object first
    if defined?(@controller) && @controller.present?
      # Set mapping directly on the controller's request environment
      @controller.request.env["devise.mapping"] = Devise.mappings[:user]
    elsif defined?(@request) && @request.present?
      # Fallback in case controller isn't fully set up
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end
  end

  # Helper to create and sign in a user in one step
  def create_and_log_in_user
    user = FactoryBot.create(:user)
    login(user)
    user
  end
end

# Add a global before hook for all controller tests
RSpec.configure do |config|
  config.include LoginHelper, type: :controller

  # IMPORTANT: Handle namespaced controllers with highest priority
  # This needs to run before any controller spec
  config.prepend_before(:each, type: :controller) do
    # For Devise controller specs, always set up mapping first thing
    if self.class.description.start_with?('Users::')
      # For namespaced controllers, we need to be even more explicit
      @request.env["devise.mapping"] = Devise.mappings[:user] if defined?(@request)
    end
  end

  # General mapping for all controllers
  config.before(:each, type: :controller) do
    # Always set the mapping at the controller level
    @request.env["devise.mapping"] = Devise.mappings[:user] if defined?(@request)
  end
end