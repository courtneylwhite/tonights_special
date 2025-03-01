class RecipePresenter
  def self.grouped_recipes(recipes, categories)
    # Format all recipes and group them by category
    grouped = recipes.map { |recipe| format_recipe(recipe) }
                     .group_by { |r| r.delete(:category) }

    # Create a hash with all categories, even empty ones
    categories.each_with_object({}) do |category, hash|
      hash[category.name] = {
        items: grouped[category.name] || [],
        id: category.id,
        display_order: category.display_order
      }
    end
  end

  def self.grouped_recipes_with_availability(recipes, categories, user)
    # Preload user groceries once to avoid N+1 queries
    user_groceries = user.groceries.includes(:unit).index_by(&:id)

    # Format all recipes with availability info and group them by category
    grouped = recipes.map do |recipe|
      # Check availability with optimized checker (using limit=1 for performance)
      availability = RecipeServices::AvailabilityChecker.new(user, recipe, user_groceries).available?

      # Add availability to the recipe data
      format_recipe(recipe).merge(can_make: availability)
    end.group_by { |r| r.delete(:category) }

    # Create a hash with all categories, even empty ones
    categories.each_with_object({}) do |category, hash|
      hash[category.name] = {
        items: grouped[category.name] || [],
        id: category.id,
        display_order: category.display_order
      }
    end
  end

  private

  def self.format_recipe(recipe)
    {
      id: recipe.id,
      name: recipe.name,
      instructions: recipe.instructions,
      notes: recipe.notes,
      completed: recipe.completed,
      completed_at: recipe.completed_at,
      category: recipe.recipe_category.name,
      emoji: "U+1F37D" # Default emoji - TODO: change this to an S3 url
    }
  end

  def self.format_recipe_with_availability(recipe, user)
    # This method is kept for backward compatibility
    # But we recommend using the grouped_recipes_with_availability method
    # which is more performant for multiple recipes

    # Check recipe availability
    availability = RecipeServices::AvailabilityChecker.new(user, recipe).available?

    # Add availability flag to the formatted recipe data
    format_recipe(recipe).merge(
      can_make: availability
    )
  end
end
