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
      # Try to find an existing grocery with this name, or create a new one
      begin
        grocery = find_or_create_grocery(ingredient_data[:name])

        # Find the correct unit
        unit = find_unit(ingredient_data[:unit_name])

        # Create the recipe_ingredient
        ingredient = recipe.recipe_ingredients.create!(
          grocery_id: grocery.id,
          quantity: ingredient_data[:quantity] || 1,
          unit_id: unit&.id,
          name: ingredient_data[:name]
        )

        { success: true, ingredient: ingredient }
      rescue => e
        { success: false, errors: ["Error creating ingredient #{ingredient_data[:name]}: #{e.message}"] }
      end
    end

    def find_or_create_grocery(name)
      Grocery.find_or_create_by(
        user_id: user.id,
        name: name
      ) do |g|
        # Default values if creating a new grocery
        g.grocery_section_id = GrocerySection.where(user_id: user.id).first&.id
        g.quantity = 1
        g.unit_id = Unit.first&.id
        g.emoji = "U+1F34E" # Default emoji (apple)
      end
    end

    def find_unit(unit_name)
      if unit_name.present?
        Unit.find_by("name ILIKE ? OR abbreviation ILIKE ?", unit_name, unit_name) || Unit.first
      else
        Unit.first
      end
    end
  end
end