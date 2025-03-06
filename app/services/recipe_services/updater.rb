# app/services/recipe_services/updater.rb
module RecipeServices
  class Updater
    attr_reader :user, :recipe, :recipe_attributes, :ingredients_attributes, :deleted_ingredient_ids

    def initialize(user, recipe, recipe_attributes, ingredients_attributes = [], deleted_ingredient_ids = [])
      @user = user
      @recipe = recipe
      @recipe_attributes = recipe_attributes || {}
      @ingredients_attributes = ingredients_attributes || []
      @deleted_ingredient_ids = deleted_ingredient_ids || []
      @errors = []
      @warnings = []
    end

    def update
      success = false

      ActiveRecord::Base.transaction do
        begin
          # Update the recipe attributes
          update_recipe

          # Delete any ingredients that were removed
          delete_removed_ingredients if @deleted_ingredient_ids.present?

          # Update recipe ingredients if provided
          update_recipe_ingredients if @ingredients_attributes.present?

          # If we get here without errors, mark as successful
          success = true
        rescue => e
          # Log the error and add to errors array
          Rails.logger.error("Recipe update failed: #{e.message}")
          @errors << "Failed to update recipe: #{e.message}"

          # Re-raise to trigger rollback
          raise
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
      # Prepare the attributes
      update_attrs = {}

      # Handle each attribute, including empty values
      if @recipe_attributes.key?(:name)
        update_attrs[:name] = @recipe_attributes[:name].present? ?
                                @recipe_attributes[:name].downcase : ""
      end

      if @recipe_attributes.key?(:notes)
        update_attrs[:notes] = @recipe_attributes[:notes].present? ?
                                 @recipe_attributes[:notes].downcase : ""
      end

      # Don't downcase instructions
      update_attrs[:instructions] = @recipe_attributes[:instructions] if @recipe_attributes.key?(:instructions)

      # Handle other fields
      update_attrs[:recipe_category_id] = @recipe_attributes[:recipe_category_id] if @recipe_attributes.key?(:recipe_category_id)
      update_attrs[:prep_time] = @recipe_attributes[:prep_time] if @recipe_attributes.key?(:prep_time)
      update_attrs[:cook_time] = @recipe_attributes[:cook_time] if @recipe_attributes.key?(:cook_time)
      update_attrs[:servings] = @recipe_attributes[:servings] if @recipe_attributes.key?(:servings)

      # Update recipe
      unless @recipe.update(update_attrs)
        @errors += @recipe.errors.full_messages
        raise ActiveRecord::Rollback
      end
    end

    def delete_removed_ingredients
      # Find the ingredients to delete
      ingredients_to_delete = @recipe.recipe_ingredients.where(id: @deleted_ingredient_ids)

      # Log what we're deleting
      Rails.logger.info("Deleting ingredients: #{ingredients_to_delete.pluck(:id)}")

      # Delete them
      ingredients_to_delete.destroy_all
    end

    def update_recipe_ingredients
      # Process each ingredient
      @ingredients_attributes.each do |ingredient_attr|
        # Skip if no id is provided
        next unless ingredient_attr[:id].present?

        # Find the ingredient
        ingredient = @recipe.recipe_ingredients.find_by(id: ingredient_attr[:id])

        # Skip if ingredient not found
        unless ingredient
          @warnings << "Couldn't find ingredient with ID: #{ingredient_attr[:id]}"
          next
        end

        # Prepare update attributes
        update_attrs = {}

        # Copy and process each attribute, handling empty strings explicitly
        update_attrs[:grocery_id] = ingredient_attr[:grocery_id] if ingredient_attr.key?(:grocery_id)
        update_attrs[:quantity] = ingredient_attr[:quantity] if ingredient_attr.key?(:quantity)
        update_attrs[:unit_id] = ingredient_attr[:unit_id] if ingredient_attr.key?(:unit_id)

        # Handle text fields that could be empty
        if ingredient_attr.key?(:name)
          update_attrs[:name] = ingredient_attr[:name].present? ? ingredient_attr[:name].downcase : ""
        end

        if ingredient_attr.key?(:preparation)
          update_attrs[:preparation] = ingredient_attr[:preparation].present? ?
                                         ingredient_attr[:preparation].downcase : ""
        end

        if ingredient_attr.key?(:size)
          update_attrs[:size] = ingredient_attr[:size].present? ?
                                  ingredient_attr[:size].downcase : ""
        end

        # Update the ingredient
        unless ingredient.update(update_attrs)
          @errors += ingredient.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end