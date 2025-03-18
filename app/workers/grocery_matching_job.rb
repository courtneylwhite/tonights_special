class GroceryMatchingJob
  include Sidekiq::Worker
  sidekiq_options queue: :matching, retry: 3

  def perform(grocery_id)
    grocery = Grocery.find_by(id: grocery_id)
    return unless grocery

    Rails.logger.info("Starting GroceryMatchingJob for grocery #{grocery.name} (ID: #{grocery.id})")

    result = MatchingService.match_grocery_to_ingredients(grocery)

    Rails.logger.info("Completed GroceryMatchingJob for grocery #{grocery.name}: " \
                        "matched #{result[:matched_ingredients]} ingredients")
  rescue StandardError => e
    Rails.logger.error("Error in GroceryMatchingJob for grocery ID #{grocery_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end