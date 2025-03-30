# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist
    mocks.verify_partial_doubles = true
  end

  # Shared context metadata
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Enable focus filtering - run only examples tagged with :focus
  config.filter_run_when_matching :focus

  # Run specs in random order to surface order dependencies
  config.order = :random

  # Allow specifying seed using --seed CLI option
  Kernel.srand config.seed

  # Enable verbose output when running a single spec file
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Save status to allow --only-failures and --next-failure options
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Add metadata to Devise controller specs to help with debugging
  config.define_derived_metadata(file_path: %r{/spec/controllers/users/}) do |metadata|
    metadata[:devise_controller] = true
  end

  # Debugging for Devise controller specs
  config.after(:each, devise_controller: true) do |example|
    if example.exception
      puts "\n*** Devise Controller Spec Failed ***"
      puts "Controller: #{controller.class.name}"
      puts "Action: #{example.metadata[:description]}"
      puts "Request env: #{request.env['devise.mapping'] ? 'Has devise.mapping' : 'MISSING devise.mapping!'}"
      puts "Response status: #{response.status}"
      puts "Response body sample: #{response.body[0..100]}..."
      puts "*******************************\n"
    end
  end
end
