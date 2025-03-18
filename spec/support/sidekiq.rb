require 'sidekiq/testing'

# Helper methods for Sidekiq testing
module SidekiqHelpers
  # Process all pending jobs
  def process_all_jobs
    Sidekiq::Worker.drain_all
  end

  # Process jobs for a specific worker class
  def process_jobs(worker_class)
    worker_class.drain
  end

  # Count jobs for a specific worker class
  def jobs_for(worker_class)
    worker_class.jobs.size
  end

  # Reload a record safely (handles nil records)
  def reload_record(record)
    return nil unless record
    record.reload if record.persisted?
    record
  end

  # Wait for database changes to propagate with timeout
  def wait_for_condition(timeout: 2, check_interval: 0.1)
    start_time = Time.now
    while Time.now - start_time < timeout
      result = yield
      return true if result
      sleep check_interval
    end
    false
  end
end

RSpec.configure do |config|
  # Include our helper methods
  config.include SidekiqHelpers

  # Clear jobs between tests
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  # Use inline mode by default for integration tests (already in your config)
  config.before(:each, type: :request) do
    Sidekiq::Testing.inline!
  end

  # Enable fake mode explicitly when needed
  config.before(:each, sidekiq: :fake) do
    Sidekiq::Testing.fake!
  end

  # Enable disabled mode explicitly when needed
  config.before(:each, sidekiq: :disabled) do
    Sidekiq::Testing.disable!
  end

  # Reset to fake mode after each test
  config.after(:each) do
    Sidekiq::Testing.fake!
  end
end
