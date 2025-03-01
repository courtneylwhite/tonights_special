module RecipeServices
  class AvailabilityChecker
    attr_reader :user, :recipe, :preloaded_groceries

    def initialize(user, recipe, preloaded_groceries = nil)
      @user = user
      @recipe = recipe
      @preloaded_groceries = preloaded_groceries
    end

    # Returns true if all ingredients are available in sufficient quantities
    # Much more performant as it stops checking after finding a single missing ingredient
    def available?
      missing_ingredients(1).empty?
    end

    # Returns a hash of information about availability
    # {
    #   available: true/false,
    #   missing_ingredients: [
    #     { name: "flour", required: 2, available: 1, unit: "cup" }
    #   ]
    # }
    # Optionally limits the number of missing ingredients returned
    def availability_info(limit = nil)
      missing = missing_ingredients(limit)

      {
        available: missing.empty?,
        missing_ingredients: missing
      }
    end

    # Returns array of missing or insufficient ingredients
    # This is made public to allow proper testing without testing private methods
    # By default returns all missing ingredients
    # With limit parameter, will stop after finding that many missing ingredients
    def missing_ingredients(limit = nil)
      missing = []

      # Use preloaded groceries if provided, otherwise load them
      user_groceries = if preloaded_groceries
                         preloaded_groceries
      else
                         user.groceries.includes(:unit).index_by(&:id)
      end

      recipe.recipe_ingredients.includes(:grocery, :unit).each do |ingredient|
        # Stop checking if we've hit our limit
        break if limit && missing.length >= limit

        # If ingredient has no grocery_id, consider it missing
        if ingredient.grocery_id.nil?
          missing << {
            name: ingredient.name,
            required: ingredient.quantity,
            required_unit: ingredient.unit&.name || "whole",
            available: 0,
            available_unit: ingredient.unit&.name || "whole"
          }
          next
        end

        # Find the matching grocery in user's pantry
        grocery = user_groceries[ingredient.grocery_id]

        # If the grocery doesn't exist or has insufficient quantity, add to missing list
        if grocery.nil? || ingredient.quantity > grocery.quantity
          missing << {
            name: ingredient.name,
            required: ingredient.quantity,
            required_unit: ingredient.unit&.name || "whole",
            available: grocery&.quantity || 0,
            available_unit: grocery&.unit&.name || "whole"
          }
        end
      end

      missing
    end

    private

    # Tries to convert between compatible units
    # Returns nil if conversion is not possible
    def convert_to_common_unit(quantity, from_unit, to_unit)
      # If units are the same, no conversion needed
      return quantity if from_unit.id == to_unit.id

      # Try to find a direct conversion
      conversion = UnitConversion.find_by(from_unit_id: from_unit.id, to_unit_id: to_unit.id)
      return quantity * conversion.conversion_factor if conversion

      # Try reverse conversion
      reverse_conversion = UnitConversion.find_by(from_unit_id: to_unit.id, to_unit_id: from_unit.id)
      return quantity / reverse_conversion.conversion_factor if reverse_conversion

      # If units are in the same category, try to find a conversion through a common unit
      if from_unit.category == to_unit.category
        # This would require more complex conversion logic
        # For now, we'll return nil for simplicity
        return nil
      end

      # If units are not compatible, return nil
      nil
    end
  end
end
