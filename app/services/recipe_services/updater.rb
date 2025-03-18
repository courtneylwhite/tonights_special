module RecipeServices
  class Updater
    attr_reader :user, :recipe, :recipe_attributes, :ingredients_attributes,
                :deleted_ingredient_ids, :new_ingredients_attributes

    def initialize(user, recipe, recipe_attributes, ingredients_attributes = [],
                   deleted_ingredient_ids = [], new_ingredients_attributes = [])
      @user = user
      @recipe = recipe
      @recipe_attributes = recipe_attributes || {}
      @ingredients_attributes = ingredients_attributes || []
      @deleted_ingredient_ids = deleted_ingredient_ids || []
      @new_ingredients_attributes = new_ingredients_attributes || []
      @errors = []
      @warnings = []
    end

    def update
      success = false
      updated_ingredients = []

      ActiveRecord::Base.transaction do
        begin
          update_recipe
          delete_removed_ingredients if @deleted_ingredient_ids.present?
          updated_ingredients = update_recipe_ingredients if @ingredients_attributes.present?
          new_ingredients = create_new_ingredients if @new_ingredients_attributes.present?
          updated_ingredients += new_ingredients if new_ingredients.is_a?(Array)

          success = true
        rescue StandardError => e
          Rails.logger.error("Recipe update failed: #{e.message}")
          @errors << "Failed to update recipe: #{e.message}"

          raise ActiveRecord::Rollback
        end
      end

      # After successful transaction, enqueue matching jobs for updated ingredients
      if success && updated_ingredients.any?
        updated_ingredients.compact.each do |ingredient_id|
          ::IngredientMatchingJob.perform_async(ingredient_id, @user.id)
        end
      end

      # Return result hash
      {
        success: success,
        recipe: success ? @recipe : nil,
        errors: @errors,
        warnings: @warnings
      }
    end

    private

    def update_recipe
      update_attrs = {}

      if @recipe_attributes.key?(:name)
        update_attrs[:name] = @recipe_attributes[:name].present? ?
                                @recipe_attributes[:name].downcase : ""
      end

      if @recipe_attributes.key?(:notes)
        update_attrs[:notes] = @recipe_attributes[:notes].present? ?
                                 @recipe_attributes[:notes].downcase : ""
      end

      update_attrs[:instructions] = @recipe_attributes[:instructions] if @recipe_attributes.key?(:instructions)
      update_attrs[:recipe_category_id] = @recipe_attributes[:recipe_category_id] if @recipe_attributes.key?(:recipe_category_id)
      update_attrs[:prep_time] = @recipe_attributes[:prep_time] if @recipe_attributes.key?(:prep_time)
      update_attrs[:cook_time] = @recipe_attributes[:cook_time] if @recipe_attributes.key?(:cook_time)
      update_attrs[:servings] = @recipe_attributes[:servings] if @recipe_attributes.key?(:servings)

      unless @recipe.update(update_attrs)
        @errors += @recipe.errors.full_messages
        raise StandardError, "Recipe validation failed"
      end
    end

    def delete_removed_ingredients
      ingredients_to_delete = @recipe.recipe_ingredients.where(id: @deleted_ingredient_ids)
      Rails.logger.info("Deleting ingredients: #{ingredients_to_delete.pluck(:id)}")
      ingredients_to_delete.destroy_all
    end

    def update_recipe_ingredients
      updated_ingredient_ids = []

      @ingredients_attributes.each do |ingredient_attr|
        next unless ingredient_attr[:id].present?

        ingredient = @recipe.recipe_ingredients.find_by(id: ingredient_attr[:id])

        unless ingredient
          @warnings << "Couldn't find ingredient with ID: #{ingredient_attr[:id]}"
          next
        end

        update_attrs = {}
        update_attrs[:grocery_id] = ingredient_attr[:grocery_id] if ingredient_attr.key?(:grocery_id)
        update_attrs[:quantity] = ingredient_attr[:quantity] if ingredient_attr.key?(:quantity)
        update_attrs[:unit_id] = ingredient_attr[:unit_id] if ingredient_attr.key?(:unit_id)

        # Check if name is being updated
        if ingredient_attr.key?(:name)
          new_name = ingredient_attr[:name].present? ? ingredient_attr[:name].downcase : ""
          update_attrs[:name] = new_name

          # Name has changed, we'll do matching asynchronously
          needs_matching = ingredient.respond_to?(:name) && new_name.downcase != ingredient.name.downcase
        end

        if ingredient_attr.key?(:preparation)
          update_attrs[:preparation] = ingredient_attr[:preparation].present? ?
                                         ingredient_attr[:preparation].downcase : ""
        end

        if ingredient_attr.key?(:size)
          update_attrs[:size] = ingredient_attr[:size].present? ?
                                  ingredient_attr[:size].downcase : ""
        end

        unless ingredient.update(update_attrs)
          @errors += ingredient.errors.full_messages
          raise StandardError, "Ingredient validation failed"
        end

        # Add this ingredient ID to the list of updated ingredients
        updated_ingredient_ids << ingredient.id
      end

      updated_ingredient_ids
    end

    def create_new_ingredients
      return [] if @new_ingredients_attributes.empty?

      # Convert the new ingredient attributes to the format expected by RecipeServices::Ingredient
      ingredients_data = @new_ingredients_attributes.map do |ingredient_attr|
        {
          name: ingredient_attr[:name].present? ? ingredient_attr[:name].strip : "",
          quantity: ingredient_attr[:quantity] || 1,
          unit_id: ingredient_attr[:unit_id],
          preparation: ingredient_attr[:preparation],
          size: ingredient_attr[:size]
        }
      end

      # Use the existing ingredient creation service
      ingredient_result = RecipeServices::Ingredient.new(
        @recipe,
        @user,
        ingredients_data
      ).create_ingredients

      # Handle any errors - match the exact wording expected by tests
      unless ingredient_result[:success]
        @warnings << "Some ingredients could not be created: #{ingredient_result[:errors].join(', ')}"

        # If there are significant errors that should trigger a rollback
        if ingredient_result[:errors].any? { |e| e.include?("Error creating ingredient") }
          @errors += ingredient_result[:errors]
          raise StandardError, "Error creating ingredients"
        end
      end

      # Return the IDs of created ingredients
      ingredient_result[:ingredients].map(&:id)
    end
  end
end