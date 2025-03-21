
module DeviseControllerHelper
  # Convenience method to login a user
  # Mapping is now automatically set up by the global before hook
  def login_user
    user = FactoryBot.create(:user)
    sign_in user
    user
  end

  # Keep this method for backward compatibility
  def setup_devise_mapping
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end
end

RSpec.configure do |config|
  # Include Devise test helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include DeviseControllerHelper, type: :controller
end
