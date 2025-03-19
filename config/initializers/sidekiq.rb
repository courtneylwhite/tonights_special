require 'redis-client'

# Fetch Redis URL from environment, with a local fallback
redis_url = ENV["REDIS_URL"] || "redis://localhost:6379/0"

Sidekiq.configure_server do |config|
  config.redis = {
    url: redis_url,
    network_timeout: 5,
    pool_timeout: 5,
    size: ENV.fetch("SIDEKIQ_CONCURRENCY", 5).to_i + 2
  }

  # Enhanced error handling
  config.error_handlers << proc { |ex, ctx_hash|
    Rails.logger.error("Sidekiq job error: #{ex.message}")
    Rails.logger.error(ex.backtrace.join("\n")) if ex.backtrace
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: redis_url,
    network_timeout: 5,
    pool_timeout: 5,
    size: 2
  }
end