class RecipePresenter
  def self.grouped_recipes(recipes, categories)
    grouped = recipes.map { |recipe| format_recipe(recipe) }
                     .group_by { |r| r.delete(:category) }

    categories.each_with_object({}) do |category, hash|
      hash[category.name] = {
        items: grouped[category.name] || [],
        id: category.id,
        display_order: category.display_order
      }
    end
  end

  def self.grouped_recipes_with_availability(recipes, categories, user)
    grouped = recipes.map do |recipe|
      # Check availability with optimized checker (using limit=1 for performance)
      availability = RecipeServices::AvailabilityChecker.new(user, recipe).available?

      format_recipe(recipe).merge(can_make: availability)
    end.group_by { |r| r.delete(:category) }

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
end
