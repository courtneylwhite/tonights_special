module RecipeServices
  class AvailabilityChecker
    attr_reader :user, :recipe

    def initialize(user, recipe)
      @user = user
      @recipe = recipe
    end

    # Returns true if all ingredients are available in sufficient quantities
    def available?
      missing_ingredients.empty?
    end

    # Returns a hash of information about availability
    # {
    #   available: true/false,
    #   missing_ingredients: [
    #     { name: "flour", required: 2, available: 1, unit: "cup" }
    #   ]
    # }
    def availability_info
      missing = missing_ingredients

      {
        available: missing.empty?,
        missing_ingredients: missing
      }
    end

    private

    def missing_ingredients
      missing = []
      user_groceries = user.groceries.includes(:unit).index_by(&:id)

      recipe.recipe_ingredients.includes(:grocery, :unit).each do |ingredient|
        # Skip ingredients without a grocery association
        next unless ingredient.grocery_id

        # Find the matching grocery in user's pantry
        grocery = user_groceries[ingredient.grocery_id]

        # If the grocery doesn't exist or has insufficient quantity, add to missing list
        if ingredient.quantity > grocery.quantity
          missing << {
            name: ingredient.name,
            required: ingredient.quantity,
            required_unit: ingredient.unit&.name || 'whole',
            available: grocery&.quantity || 0,
            available_unit: grocery&.unit&.name || 'whole'
          }
        end
      end

      missing
    end

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