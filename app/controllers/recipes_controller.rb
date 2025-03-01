class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [:show, :edit, :update, :destroy, :mark_completed, :mark_incomplete]

  def index
    @recipes = current_user.recipes.includes(:recipe_category, recipe_ingredients: [:grocery, :unit])
                           .order(created_at: :desc)
    @recipe_categories = current_user.recipe_categories.order(display_order: :asc)

    # Uses the optimized grouped_recipes_with_availability which preloads groceries once
    @grouped_recipes = RecipePresenter.grouped_recipes_with_availability(@recipes, @recipe_categories, current_user)

    respond_to do |format|
      format.html # Renders the index page with React components
      format.json { render json: @grouped_recipes }
    end
  end

  def show
    # Preload groceries for performance
    user_groceries = current_user.groceries.includes(:unit).index_by(&:id)

    @recipe_availability = RecipeServices::AvailabilityChecker.new(
      current_user,
      @recipe,
      user_groceries
    ).availability_info(2)

    respond_to do |format|
      format.html # Renders show page with React components
      format.json {
        render json: {
          recipe: {
            id: @recipe.id,
            name: @recipe.name,
            instructions: @recipe.instructions,
            notes: @recipe.notes,
            category: @recipe.recipe_category.name,
            completed: @recipe.completed,
            completed_at: @recipe.completed_at,
            availability: @recipe_availability,
            ingredients: @recipe.recipe_ingredients.includes(:grocery, :unit).map do |ingredient|
              {
                id: ingredient.id,
                grocery_name: ingredient.grocery&.name || "Unknown",
                quantity: ingredient.quantity,
                unit: ingredient.unit.name,
                preparation: ingredient.preparation,
                size: ingredient.size
              }
            end
          }
        }
      }
    end
  end

  def new
    @recipe = Recipe.new
    @recipe_categories = current_user.recipe_categories.order(:name)

    # If this is an AJAX request, return category data as JSON
    respond_to do |format|
      format.html
      format.json { render json: { categories: @recipe_categories } }
    end
  end

  def edit
    @recipe_categories = current_user.recipe_categories.order(:name)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          recipe: format_recipe_for_json(@recipe),
          categories: @recipe_categories
        }
      }
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

  def update
    if @recipe.update(recipe_params)
      render json: {
        status: "success",
        message: "Recipe was successfully updated.",
        recipe: format_recipe_for_json(@recipe)
      }
    else
      render json: {
        status: "error",
        errors: @recipe.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    render json: {
      status: "success",
      message: "Recipe was successfully deleted."
    }
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
    params.require(:recipe).permit(:name, :ingredients, :instructions, :notes, :recipe_category_id)
  end

  def format_recipe_for_json(recipe)
    {
      id: recipe.id,
      name: recipe.name,
      instructions: recipe.instructions,
      notes: recipe.notes,
      category: recipe.recipe_category&.name,
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