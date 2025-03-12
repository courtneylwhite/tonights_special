module RecipeServices
  class AvailabilityChecker
    attr_reader :user, :recipe

    def initialize(user, recipe)
      @user = user
      @recipe = recipe
    end

    # Returns true if all ingredients have a grocery_id, false otherwise
    # Stops checking after finding a single missing ingredient if limit=1
    def available?(limit = 1)
      missing_ingredients(limit).empty?
    end

    # Returns an array of ingredients without grocery_id
    # Limit parameter controls how many missing ingredients to find before stopping
    # - With limit=nil: returns all missing ingredients
    # - With limit=1: returns early after finding one missing ingredient (for performance)
    def missing_ingredients(limit = nil)
      missing = []

      recipe.recipe_ingredients.each do |ingredient|
        # Stop checking if we've hit our limit
        break if limit && missing.length >= limit

        # If ingredient has no grocery_id, consider it missing
        if ingredient.grocery_id.nil?
          missing << {
            name: ingredient.name,
            id: ingredient.id
          }
        end
      end

      missing
    end

    # Returns a hash of information about availability
    # {
    #   available: true/false,
    #   missing_ingredients: [
    #     { name: "flour", id: 123 }
    #   ]
    # }
    def availability_info(limit = nil)
      missing = missing_ingredients(limit)

      {
        available: missing.empty?,
        missing_ingredients: missing
      }
    end
  end
end
