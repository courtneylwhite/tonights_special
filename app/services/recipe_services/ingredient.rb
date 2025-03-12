module RecipeServices
  class Ingredient
    attr_reader :recipe, :user, :ingredients_data

    def initialize(recipe, user, ingredients_data = [])
      @recipe = recipe
      @user = user
      @ingredients_data = ingredients_data || [] # Handle nil explicitly
    end

    def create_ingredients
      return { success: true, ingredients: [] } if ingredients_data.blank?

      created_ingredients = []
      errors = []

      ingredients_data.each do |ingredient_data|
        if ingredient_data.blank?
          errors << "Empty ingredient data provided"
          next
        end

        if ingredient_data[:name].blank?
          errors << "Error creating ingredient: Name can't be blank"
          next
        end

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
      begin
        ingredient_name = UtilityService.normalize_text(ingredient_data[:name])
        unit = find_unit_for_ingredient(ingredient_data)
        quantity = UtilityService.format_quantity(ingredient_data[:quantity] || 1)

        ingredient_attributes = {
          name: ingredient_name,
          quantity: quantity,
          unit_id: unit&.id
        }

        ingredient_attributes[:preparation] = ingredient_data[:preparation] if ingredient_data[:preparation].present?
        ingredient_attributes[:size] = ingredient_data[:size] if ingredient_data[:size].present?
        ingredient = recipe.recipe_ingredients.create!(ingredient_attributes)

        begin
          match_with_grocery(ingredient)
        rescue => e
          Rails.logger.error("Error matching grocery for #{ingredient.name}: #{e.message}")
        end

        { success: true, ingredient: ingredient }
      rescue => e
        { success: false, errors: [ "Error creating ingredient #{ingredient_data[:name]}: #{e.message}" ] }
      end
    end

    def match_with_grocery(ingredient)
      grocery = MatchingService.match_ingredient_to_grocery(user, ingredient.name)
      ingredient.update(grocery_id: grocery.id) if grocery
    end

    def find_unit_for_ingredient(ingredient_data)
      if ingredient_data[:unit_id].present?
        unit = Unit.find_by(id: ingredient_data[:unit_id])
        return unit if unit
      end

      if ingredient_data[:unit_name].present?
        return find_unit_by_name(ingredient_data[:unit_name])
      end

      Unit.find_by(name: 'whole') || Unit.first
    end

    def find_unit_by_name(unit_name)
      normalized_name = UtilityService.normalize_unit_name(unit_name)

      # First try direct case-insensitive match
      unit = Unit.find_by("LOWER(name) = ?", normalized_name.downcase)
      return unit if unit

      # Then try abbreviation match
      unit = Unit.find_by("LOWER(abbreviation) = ?", unit_name.downcase)
      return unit if unit

      # Try partial name match
      unit = Unit.where("LOWER(name) LIKE ?", "#{normalized_name.downcase}%").first
      return unit if unit

      # Create new unit as last resort
      unit = create_new_unit(normalized_name)
      return unit if unit

      # Fallback to whole unit
      Unit.find_by(name: 'whole') || Unit.first
    end

    def create_new_unit(unit_name)
      category = UtilityService.determine_unit_category(unit_name)
      abbreviation = unit_name.length > 3 ? unit_name[0..2] : unit_name

      Unit.create!(
        name: unit_name,
        category: category,
        abbreviation: abbreviation.strip
      )
    rescue => e
      Rails.logger.error("Error creating new unit '#{unit_name}': #{e.message}")
      nil
    end
  end
end
