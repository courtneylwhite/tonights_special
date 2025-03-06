module RecipeServices
  class Ingredient
    attr_reader :recipe, :user, :ingredients_data

    def initialize(recipe, user, ingredients_data = [])
      @recipe = recipe
      @user = user
      @ingredients_data = ingredients_data
    end

    def create_ingredients
      return { success: true, ingredients: [] } if ingredients_data.blank?

      created_ingredients = []
      errors = []

      ingredients_data.each do |ingredient_data|
        result = create_single_ingredient(ingredient_data)

        if result[:success]
          created_ingredients << result[:ingredient]
        else
          errors << result[:errors]
        end
      end

      if errors.empty?
        { success: true, ingredients: created_ingredients }
      else
        { success: false, errors: errors.flatten }
      end
    end

    private

    def create_single_ingredient(ingredient_data)
      # Try to find an existing grocery with this name
      begin
        # Standardize the name to lowercase
        ingredient_name = ingredient_data[:name].strip.downcase

        grocery = find_grocery_by_name(ingredient_name)

        # Find the correct unit - prioritize unit_id if provided
        unit = if ingredient_data[:unit_id].present?
                 Unit.find_by(id: ingredient_data[:unit_id])
               else
                 find_unit(ingredient_data[:unit_name])
               end

        # Fallback to default unit if not found or not provided
        unit ||= Unit.find_by(name: 'whole') || Unit.first

        # Format quantity to have at most 2 decimal places
        quantity = format_quantity(ingredient_data[:quantity] || 1)

        # Create the recipe_ingredient with preparation and size if available
        ingredient_attributes = {
          grocery_id: grocery&.id,  # May be nil if no matching grocery was found
          quantity: quantity,
          unit_id: unit&.id,
          name: ingredient_name
        }

        # Add preparation and size if they exist
        ingredient_attributes[:preparation] = ingredient_data[:preparation] if ingredient_data[:preparation].present?
        ingredient_attributes[:size] = ingredient_data[:size] if ingredient_data[:size].present?

        ingredient = recipe.recipe_ingredients.create!(ingredient_attributes)

        { success: true, ingredient: ingredient }
      rescue => e
        { success: false, errors: [ "Error creating ingredient #{ingredient_data[:name]}: #{e.message}" ] }
      end
    end

    # Format quantity to have at most 2 decimal places
    def format_quantity(quantity)
      return quantity unless quantity.is_a?(Numeric)

      # Convert to a decimal with 2 decimal places (rounds to nearest)
      quantity = (quantity * 100).round / 100.0

      # If it's a whole number, convert to integer
      quantity.to_i == quantity ? quantity.to_i : quantity
    end

    def find_grocery_by_name(name)
      # Use the new GroceryMatcher service to find a matching grocery
      GroceryMatcher.find_grocery_by_name(user, name)
    end

    def find_unit(unit_name)
      if unit_name.present?
        # Normalize the unit name first
        normalized_unit_name = normalize_unit_name(unit_name)

        # Try to find by exact name match first
        unit = Unit.find_by("LOWER(name) = ?", normalized_unit_name.downcase)

        # If not found, try to find by abbreviation
        unless unit
          unit = Unit.find_by("LOWER(abbreviation) = ?", unit_name.downcase)
        end

        # If still not found, try to match the beginning of the unit name
        # This helps with cases like "tbsp" matching "tablespoon"
        unless unit
          unit = Unit.where("LOWER(name) LIKE ?", "#{normalized_unit_name.downcase}%").first
        end

        # If not found, create a new unit
        unless unit
          unit = create_new_unit(normalized_unit_name)
        end

        # Return the found or created unit or default to 'whole'
        unit || Unit.find_by(name: 'whole') || Unit.first
      else
        # Default to 'whole' unit for countable items
        Unit.find_by(name: 'whole') || Unit.first
      end
    end

    def normalize_unit_name(unit_name)
      # Remove trailing periods and normalize common abbreviations
      clean_name = unit_name.downcase.gsub(/\.$/, '')

      case clean_name
      when 'tbsp', 'tbsps', 'tbs', 'tblsp'
        'tablespoon'
      when 'tsp', 'tsps'
        'teaspoon'
      when 'c'
        'cup'
      when 'oz', 'ozs'
        'ounce'
      when 'lb', 'lbs'
        'pound'
      when 'g'
        'gram'
      when 'kg'
        'kilogram'
      when 'ml'
        'milliliter'
      when 'l'
        'liter'
      when 'pt'
        'pint'
      when 'qt'
        'quart'
      when 'gal'
        'gallon'
      else
        unit_name.strip
      end
    end

    def create_new_unit(unit_name)
      # Try to determine the category based on the unit name
      category = determine_unit_category(unit_name)

      # Downcase and clean the unit name
      normalized_name = unit_name.downcase.strip

      # Create abbreviation based on first letter or first few letters
      abbreviation = normalized_name.length > 3 ? normalized_name[0..2] : normalized_name

      # Create the new unit
      Unit.create!(
        name: normalized_name,
        category: category,
        abbreviation: abbreviation.strip
      )
    rescue => e
      # Log the error but don't crash the process
      Rails.logger.error("Error creating new unit '#{unit_name}': #{e.message}")
      nil
    end

    def determine_unit_category(unit_name)
      volume_units = [ 'cup', 'tablespoon', 'teaspoon', 'pint', 'quart', 'gallon', 'liter', 'milliliter', 'fluid' ]
      weight_units = [ 'pound', 'ounce', 'gram', 'kilogram' ]
      length_units = [ 'inch', 'centimeter', 'millimeter', 'meter' ]

      unit_downcase = unit_name.downcase

      if volume_units.any? { |u| unit_downcase.include?(u) }
        'volume'
      elsif weight_units.any? { |u| unit_downcase.include?(u) }
        'weight'
      elsif length_units.any? { |u| unit_downcase.include?(u) }
        'length'
      else
        'other'
      end
    end
  end
end
