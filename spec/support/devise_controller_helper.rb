module DeviseControllerHelper
  def setup_devise_mapping
    @request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["devise.mapping"] = Devise.mappings[:user] if defined?(request)
  end

  def login_user
    setup_devise_mapping
    user = FactoryBot.create(:user)
    sign_in user
    user
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include DeviseControllerHelper, type: :controller

  # Setup the Devise mapping for all controller tests
  config.before(:each, type: :controller) do
    @request.env["devise.mapping"] = Devise.mappings[:user] if defined?(@request)
    request.env["devise.mapping"] = Devise.mappings[:user] if defined?(request)
  end
end
