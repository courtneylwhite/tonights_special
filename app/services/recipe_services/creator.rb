module RecipeServices
  class Creator
    attr_reader :user, :recipe_attributes, :new_category_params
    attr_accessor :new_category_params

    def initialize(user, recipe_attributes)
      @user = user
      @recipe_attributes = recipe_attributes
      @new_category_params = nil
    end

    def create
      warnings = []

      result = ActiveRecord::Base.transaction do
        # Step 1: Determine the category for the recipe
        category_id = get_category_id
        if category_id.nil? && new_category_params.present?
          return { success: false, errors: [ "Failed to create category" ] }
        end

        # Step 2: Set up recipe attributes
        recipe_data = {
          name: recipe_attributes[:name],
          instructions: recipe_attributes[:instructions],
          notes: recipe_attributes[:notes],
          recipe_category_id: category_id,
          user_id: user.id
        }

        # Step 3: Create and save the recipe
        recipe = Recipe.new(recipe_data)

        unless recipe.save
          Rails.logger.error("Recipe save error: #{recipe.errors.full_messages}")
          return { success: false, errors: recipe.errors.full_messages }
        end

        # Step 4: Parse the ingredients and create recipe_ingredients records
        if recipe_attributes[:ingredients].present?
          begin
            # Parse the ingredients
            parser = RecipeServices::Parser.new(recipe_attributes[:ingredients])
            parsed_data = parser.parse_ingredients_only

            # Add any extracted notes to the recipe
            if parsed_data[:notes].present?
              existing_notes = recipe.notes.to_s.strip
              note_text = parsed_data[:notes].join("\n")

              updated_notes = if existing_notes.present?
                                "#{existing_notes}\n\n#{note_text}"
              else
                                note_text
              end

              recipe.update(notes: updated_notes)
            end

            # Create the ingredient records
            if parsed_data[:ingredients].present?
              ingredient_result = RecipeServices::Ingredient.new(
                recipe,
                user,
                parsed_data[:ingredients]
              ).create_ingredients

              unless ingredient_result[:success]
                warning_message = "Some ingredients could not be created: #{ingredient_result[:errors].join(', ')}"
                warnings << warning_message

                # Important: Roll back the transaction if ingredient creation fails
                if ingredient_result[:errors].any? { |e| e.include?("Error creating ingredient") }
                  return { success: false, errors: [ warning_message ] }
                end
              end
            else
              # If ingredients text was provided but nothing was parsed successfully
              if recipe_attributes[:ingredients].strip.present?
                warnings << "No ingredients could be parsed from the provided text"
              end
            end
          rescue => e
            Rails.logger.error("Ingredient processing error: #{e.message}")
            error_message = "Error processing ingredients: #{e.message}"
            warnings << error_message
          end
        end

        # Return success result with the recipe and any warnings
        { success: true, recipe: recipe, warnings: warnings.presence }
      end

      # The transaction will return our result hash
      result
    end

    private

    def get_category_id
      if new_category_params.present?
        result = RecipeServices::Category.new(user, new_category_params).create_new_category
        result[:success] ? result[:category].id : nil
      else
        recipe_attributes[:recipe_category_id]
      end
    end
  end
end
