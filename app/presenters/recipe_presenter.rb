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

  private

  def self.format_recipe(recipe)
    {
      id: recipe.id,
      name: recipe.name,
      instructions: recipe.instructions,
      notes: recipe.notes,
      completed: recipe.completed,
      completed_at: recipe.completed_at,
      category: recipe.recipe_category.name
    }
  end
end