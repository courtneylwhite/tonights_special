class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [ :mark_completed, :mark_incomplete ]

  def index
    @recipes = current_user.recipes.includes(:recipe_category, recipe_ingredients: [ :grocery, :unit ])
                           .order(created_at: :desc)
    @recipe_categories = current_user.recipe_categories.order(display_order: :asc)

    # Uses the optimized grouped_recipes_with_availability which preloads groceries once
    @grouped_recipes = RecipePresenter.grouped_recipes_with_availability(@recipes, @recipe_categories, current_user)

    respond_to do |format|
      format.html # Renders the index page with React components
      format.json { render json: @grouped_recipes }
    end
  end

  def create
    # Create a new RecipeServices::Creator instance with the recipe params
    creator = ::RecipeServices::Creator.new(current_user, recipe_params)

    # If there's a new category being created, pass that data to the creator
    if params[:new_category].present?
      creator.new_category_params = params[:new_category]
    end

    # Call the create method
    result = creator.create

    if result[:success]
      render json: {
        status: "success",
        message: result[:warnings].present? ? result[:warnings].join(", ") : "Recipe was successfully created.",
        recipe: format_recipe_for_json(result[:recipe])
      }, status: :created
    else
      render json: {
        status: "error",
        errors: result[:errors]
      }, status: :unprocessable_entity
    end
  end

  def show
    @recipe = current_user.recipes
                          .includes(:recipe_category,
                                    recipe_ingredients: [:grocery, :unit])
                          .find(params[:id])

    # Load all available units for dropdown options
    @units = Unit.all.order(:category, :name)

    # Load all recipe categories for the user
    @recipe_categories = current_user.recipe_categories.order(display_order: :asc)

    # Format recipe ingredients for the React component
    # This ensures all necessary data is available
    @recipe_ingredients = @recipe.recipe_ingredients.map do |ri|
      {
        id: ri.id,
        recipe_id: @recipe.id,
        grocery_id: ri.grocery_id,
        name: ri.name,
        quantity: ri.quantity,
        unit_id: ri.unit_id,
        unit_name: ri.unit.name,
        unit_abbreviation: ri.unit.abbreviation,
        preparation: ri.preparation,
        size: ri.size
      }
    end

    respond_to do |format|
      format.html
      format.json {
        render json: {
          recipe: @recipe,
          recipe_ingredients: @recipe_ingredients,
          units: @units,
          recipe_categories: @recipe_categories
        }
      }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to recipes_path, alert: "Recipe not found." }
      format.json { render json: { error: "Recipe not found." }, status: :not_found }
    end
  end

  # app/controllers/recipes_controller.rb
  # Update action using the revised service object

  def update
    @recipe = current_user.recipes.find(params[:id])

    # Extract the recipe attributes from params
    recipe_attributes = params[:recipe] || {}

    # Extract the recipe ingredients attributes from params
    ingredients_attributes = params[:recipe_ingredients] || []

    # Extract new recipe ingredients attributes from params
    new_ingredients_attributes = params[:new_recipe_ingredients] || []

    # Extract deleted ingredient IDs
    deleted_ingredient_ids = params[:deleted_ingredient_ids] || []

    # Create a new updater service with the extracted attributes
    updater = RecipeServices::Updater.new(
      current_user,
      @recipe,
      recipe_attributes,
      ingredients_attributes,
      deleted_ingredient_ids,
      new_ingredients_attributes
    )

    # Call the update method
    result = updater.update

    if result[:success]
      # Reload associations to ensure we have the latest data
      @recipe.reload

      # Format ingredients for the response
      recipe_ingredients = @recipe.recipe_ingredients.map do |ri|
        {
          id: ri.id,
          recipe_id: @recipe.id,
          grocery_id: ri.grocery_id,
          name: ri.name,
          quantity: ri.quantity,
          unit_id: ri.unit_id,
          unit_name: ri.unit&.name,
          unit_abbreviation: ri.unit&.abbreviation,
          preparation: ri.preparation,
          size: ri.size
        }
      end

      render json: {
        recipe: @recipe,
        recipe_ingredients: recipe_ingredients,
        status: "success",
        message: result[:warnings].present? ? result[:warnings].join(", ") : "Recipe was successfully updated."
      }
    else
      render json: {
        status: "error",
        errors: result[:errors]
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe = current_user.recipes.find(params[:id])

    # Delete associated recipe ingredients first
    @recipe.recipe_ingredients.destroy_all

    # Then delete the recipe
    @recipe.destroy

    respond_to do |format|
      format.html { redirect_to recipes_path, notice: "Recipe was successfully deleted." }
      format.json { render json: { status: "success", message: "Recipe was successfully deleted." } }
    end
  end

  def mark_completed
    @recipe.update(completed: true, completed_at: Time.current)
    render json: {
      status: "success",
      message: "Recipe marked as completed.",
      recipe: format_recipe_for_json(@recipe)
    }
  end

  def mark_incomplete
    @recipe.update(completed: false, completed_at: nil)
    render json: {
      status: "success",
      message: "Recipe marked as incomplete.",
      recipe: format_recipe_for_json(@recipe)
    }
  end

  # For testing the parser
  def parse_test
    if request.post? && params[:recipe_text].present?
      @parsed_data = RecipeServices::Parser.new(params[:recipe_text]).parse
    end

    respond_to do |format|
      format.html # Renders the parse_test view
      format.json { render json: @parsed_data }
    end
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :ingredients, :instructions, :notes, :size, :preparation, :recipe_category_id, :cook_time, :prep_time, :servings)
  end

  def update_recipe_ingredients(recipe, ingredients_params)
    # Process each ingredient
    ingredients_params.each do |ingredient_param|
      # Downcase text fields
      downcased_ingredient = downcase_ingredient_params(ingredient_param)

      # Find and update the ingredient or skip if ID is invalid
      if ingredient_param[:id].present?
        ingredient = recipe.recipe_ingredients.find_by(id: ingredient_param[:id])
        ingredient&.update(downcased_ingredient)
      end
    end
  end

  # Helper method to downcase text parameters
  def downcase_params(params)
    result = params.dup

    # Downcase text fields
    result[:name] = params[:name].downcase if params[:name].present?
    result[:notes] = params[:notes].downcase if params[:notes].present?

    # Don't downcase instructions as they might have formatting that's important

    result
  end

  # Helper method to downcase ingredient parameters
  def downcase_ingredient_params(params)
    result = params.dup

    # Downcase text fields
    result[:name] = params[:name].downcase if params[:name].present?
    result[:preparation] = params[:preparation].downcase if params[:preparation].present?
    result[:size] = params[:size].downcase if params[:size].present?

    result
  end

  # In RecipesController
  def format_recipe_for_json(recipe)
    {
      id: recipe.id,
      name: recipe.name,
      instructions: recipe.instructions,
      notes: recipe.notes,
      category: recipe.recipe_category&.name,
      # Add these fields to include them in the response
      prep_time: recipe.prep_time,
      cook_time: recipe.cook_time,
      servings: recipe.servings,
      completed: recipe.completed,
      completed_at: recipe.completed_at,
      ingredients: recipe.recipe_ingredients.includes(:grocery, :unit).map do |ri|
        {
          id: ri.id,
          grocery_name: ri.grocery&.name,
          quantity: ri.quantity,
          unit: ri.unit&.name,
          preparation: ri.preparation,
          size: ri.size
        }
      end
    }
  end
end
