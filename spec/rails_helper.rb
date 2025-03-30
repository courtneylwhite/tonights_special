# Set up SimpleCov for test coverage
require 'simplecov'
SimpleCov.start 'rails'

# Environment setup
ENV['RAILS_ENV'] ||= 'test'

# Core framework requires - this loads Rails
require_relative '../config/environment'

# Now we can check Rails environment
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'spec_helper'

# Load support files
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Database configuration
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# RSpec configuration
RSpec.configure do |config|
  # Fixture configuration
  config.fixture_paths = [ Rails.root.join('spec/fixtures') ]
  config.use_transactional_fixtures = true

  # Factory Bot
  config.include FactoryBot::Syntax::Methods

  # Authentication test helpers (Devise & Warden)
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers

  config.before(:suite) do
    Warden.test_mode!
  end

  config.after(:each) do
    Warden.test_reset!
  end

  # Automatically set up Devise mappings for controller tests
  config.before(:each, type: :controller) do
    # Check if the controller is in the Users namespace
    if defined?(controller) && controller.present? && controller.class.name.start_with?('Users::')
      # Set up Devise mapping
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end
  end

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!
  # Uncomment to filter specific gems from backtraces
  # config.filter_gems_from_backtrace("gem name")
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
