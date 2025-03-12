class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [ :mark_completed, :mark_incomplete ]

  def index
    @recipes = current_user.recipes.includes(:recipe_category, recipe_ingredients: [ :grocery, :unit ])
                           .order(created_at: :desc)
    @recipe_categories = current_user.recipe_categories.order(display_order: :asc)
    @grouped_recipes = RecipePresenter.grouped_recipes_with_availability(@recipes, @recipe_categories, current_user)

    respond_to do |format|
      format.html
      format.json { render json: @grouped_recipes }
    end
  end

  def create
    creator = ::RecipeServices::Creator.new(current_user, recipe_params)

    if params[:new_category].present?
      creator.new_category_params = params[:new_category]
    end

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
                                    recipe_ingredients: [ :grocery, :unit ])
                          .find(params[:id])

    @units = Unit.all.order(:category, :name)
    @recipe_categories = current_user.recipe_categories.order(display_order: :asc)
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

  def update
    @recipe = current_user.recipes.find(params[:id])
    recipe_attributes = params[:recipe] || {}
    ingredients_attributes = params[:recipe_ingredients] || []
    new_ingredients_attributes = params[:new_recipe_ingredients] || []
    deleted_ingredient_ids = params[:deleted_ingredient_ids] || []

    updater = RecipeServices::Updater.new(
      current_user,
      @recipe,
      recipe_attributes,
      ingredients_attributes,
      deleted_ingredient_ids,
      new_ingredients_attributes
    )

    result = updater.update

    if result[:success]
      @recipe.reload
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

    # Use a transaction to ensure all related records are deleted together
    ActiveRecord::Base.transaction do
      # The dependent: :destroy association will handle the recipe_ingredients deletion
      @recipe.destroy
    end

    respond_to do |format|
      format.html { redirect_to recipes_path, notice: "Recipe was successfully deleted." }
      format.json { render json: { status: "success", message: "Recipe was successfully deleted." } }
    end
  rescue => e
    Rails.logger.error("Recipe deletion failed: #{e.message}")
    respond_to do |format|
      format.html { redirect_to recipes_path, alert: "Failed to delete recipe." }
      format.json { render json: { status: "error", message: "Failed to delete recipe." }, status: :unprocessable_entity }
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

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :ingredients, :instructions, :notes, :size, :preparation, :recipe_category_id, :cook_time, :prep_time, :servings)
  end

  def format_recipe_for_json(recipe)
    {
      id: recipe.id,
      name: recipe.name,
      instructions: recipe.instructions,
      notes: recipe.notes,
      category: recipe.recipe_category&.name,
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
