class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [ :show, :edit, :update, :destroy, :mark_completed, :mark_incomplete ]

  def index
    @recipes = current_user.recipes.includes(:recipe_category, recipe_ingredients: [ :grocery, :unit ])
                           .order(created_at: :desc)
    @recipe_categories = current_user.recipe_categories.order(display_order: :asc)

    # Uses the optimized grouped_recipes_with_availability which preloads groceries once
    @grouped_recipes = RecipePresenter.grouped_recipes_with_availability(@recipes, @recipe_categories, current_user)

    respond_to do |format|
      format.html # This will render your index.html.erb
      format.json { render json: @grouped_recipes }
    end
  end

  def show
    # Preload groceries for performance
    user_groceries = current_user.groceries.includes(:unit).index_by(&:id)

    # Use the limit parameter to get at most 2 missing ingredients
    # This makes the response more focused and improves performance
    @recipe_availability = RecipeServices::AvailabilityChecker.new(
      current_user,
      @recipe,
      user_groceries
    ).availability_info(2)

    respond_to do |format|
      format.html
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
                unit: ingredient.unit.name
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
  end

  def edit
    @recipe_categories = current_user.recipe_categories.order(:name)
  end

  def create
    result = ::RecipeServices::Creator.new(current_user, params).create

    respond_to do |format|
      if result[:success]
        notice = result[:warnings].present? ? result[:warnings].join(", ") : "Recipe was successfully created."

        format.html { redirect_to result[:recipe], notice: notice }
        format.json {
          response_data = {
            status: "success",
            message: notice,
            recipe: {
              id: result[:recipe].id,
              name: result[:recipe].name,
              instructions: result[:recipe].instructions,
              notes: result[:recipe].notes,
              category: result[:recipe].recipe_category.name,
              ingredients: result[:recipe].recipe_ingredients.includes(:grocery, :unit).map do |ri|
                {
                  id: ri.id,
                  grocery_name: ri.grocery&.name,
                  quantity: ri.quantity,
                  unit: ri.unit&.name
                }
              end
            }
          }

          render json: response_data, status: :created
        }
      else
        format.html {
          @recipe = Recipe.new(params.require(:recipe).permit(:name, :instructions, :notes, :recipe_category_id))
          @recipe_categories = current_user.recipe_categories.order(:name)
          flash.now[:alert] = result[:errors].join(", ")
          render :new
        }
        format.json { render json: { status: "error", errors: result[:errors] }, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: "Recipe was successfully updated." }
        format.json { render json: { status: "success", message: "Recipe was successfully updated." } }
      else
        format.html {
          @recipe_categories = current_user.recipe_categories.order(:name)
          render :edit
        }
        format.json { render json: { status: "error", errors: @recipe.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @recipe.destroy
    respond_to do |format|
      format.html { redirect_to recipes_url, notice: "Recipe was successfully deleted." }
      format.json { render json: { status: "success", message: "Recipe was successfully deleted." } }
    end
  end

  def mark_completed
    @recipe.update(completed: true, completed_at: Time.current)
    respond_to do |format|
      format.html { redirect_to @recipe, notice: "Recipe marked as completed." }
      format.json { render json: { status: "success", message: "Recipe marked as completed." } }
    end
  end

  def mark_incomplete
    @recipe.update(completed: false, completed_at: nil)
    respond_to do |format|
      format.html { redirect_to @recipe, notice: "Recipe marked as incomplete." }
      format.json { render json: { status: "success", message: "Recipe marked as incomplete." } }
    end
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :instructions, :notes, :recipe_category_id)
  end
end