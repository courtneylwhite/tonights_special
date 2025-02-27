module RecipeServices
  class Creator
    attr_reader :user, :params

    def initialize(user, params)
      @user = user
      @params = params
    end

    def create
      # Handle new category creation if needed
      category_id = get_category_id

      return { success: false, errors: [ "Failed to create category" ] } if category_id.nil? && params[:new_category].present?

      # Create the recipe_services with the category
      recipe_attributes = recipe_params.merge(
        recipe_category_id: category_id,
        user_id: user.id
      )

      # Parse the instructions to separate ingredients and instructions
      parsed_data = {}
      if recipe_attributes[:instructions].present?
        parsed_data = RecipeServices::Parser.new(recipe_attributes[:instructions]).parse

        # Update instructions with just the instructions part
        recipe_attributes[:instructions] = parsed_data[:instructions]
      end

      # Create the recipe_services
      recipe = Recipe.new(recipe_attributes)

      if recipe.save
        # Create recipe_services ingredients
        if parsed_data[:ingredients].present?
          ingredient_result = RecipeServices::Ingredient.new(
            recipe,
            user,
            parsed_data[:ingredients]
          ).create_ingredients

          unless ingredient_result[:success]
            return {
              success: true,
              recipe: recipe,
              warnings: [ "Recipe saved but some ingredients could not be created: #{ingredient_result[:errors].join(', ')}" ]
            }
          end
        end

        { success: true, recipe: recipe }
      else
        { success: false, errors: recipe.errors.full_messages }
      end
    end

    private

    def get_category_id
      if params[:new_category].present?
        result = RecipeServices::Category.new(user, params[:new_category]).create_new_category
        result[:success] ? result[:category].id : nil
      else
        params[:recipe][:recipe_category_id]
      end
    end

    def recipe_params
      params.require(:recipe).permit(:name, :instructions, :notes)
    end
  end
end
