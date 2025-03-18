class RecipeBatchMatchingJob
  include Sidekiq::Worker
  sidekiq_options queue: :matching, retry: 3

  def perform(recipe_id)
    recipe = Recipe.find_by(id: recipe_id)
    return unless recipe

    user_id = recipe.user_id

    Rails.logger.info("Starting batch matching for recipe #{recipe.name} (ID: #{recipe_id})")

    # Find unmatched ingredients
    unmatched_ingredients = recipe.recipe_ingredients.where(grocery_id: nil)
    count = unmatched_ingredients.count

    unmatched_ingredients.each do |ingredient|
      # Enqueue individual matching jobs
      ::IngredientMatchingJob.perform_async(ingredient.id, user_id)
    end

    Rails.logger.info("Enqueued #{count} ingredient matching jobs for recipe #{recipe.name}")
  rescue StandardError => e
    Rails.logger.error("Error in RecipeBatchMatchingJob for recipe ID #{recipe_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end