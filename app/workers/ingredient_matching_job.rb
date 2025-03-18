class IngredientMatchingJob
  include Sidekiq::Worker
  sidekiq_options queue: :matching, retry: 3

  def perform(ingredient_id, user_id)
    ingredient = RecipeIngredient.find_by(id: ingredient_id)
    return unless ingredient

    user = User.find_by(id: user_id)
    return unless user

    Rails.logger.info("Starting IngredientMatchingJob for ingredient #{ingredient.name} (ID: #{ingredient.id})")

    grocery = MatchingService.match_ingredient_to_grocery(user, ingredient.name)
    if grocery
      ingredient.update(grocery_id: grocery.id)
      Rails.logger.info("Matched ingredient #{ingredient.name} with grocery #{grocery.name}")
    else
      Rails.logger.info("No matching grocery found for ingredient #{ingredient.name}")
    end
  rescue StandardError => e
    Rails.logger.error("Error in IngredientMatchingJob for ingredient ID #{ingredient_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end