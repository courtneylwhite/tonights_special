module RequestSpecHelper
  include Warden::Test::Helpers

  def self.included(base)
    base.before(:each) { Warden.test_mode! }
    base.after(:each) { Warden.test_reset! }
  end

  def sign_in(user)
    login_as(user, scope: :user)
  end

  def sign_out
    logout(:user)
  end
end

RSpec.configure do |config|
  # Include the helper for request specs
  config.include RequestSpecHelper, type: :request

  # Also include the helper for integration specs
  config.include RequestSpecHelper, type: :integration
end
