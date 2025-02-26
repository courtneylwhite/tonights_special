# app/controllers/recipes_controller.rb
class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [:show, :edit, :update, :destroy, :mark_completed, :mark_incomplete]

  def index
    @recipes = current_user.recipes.includes(:recipe_category)
                           .order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          recipes: @recipes.map do |recipe|
            {
              id: recipe.id,
              name: recipe.name,
              category: recipe.recipe_category.name,
              completed: recipe.completed,
              completed_at: recipe.completed_at
            }
          end
        }
      }
    end
  end

  def show
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
    # Handle new category creation if needed
    if params[:new_category].present?
      # Create the category manually instead of using the association directly
      category = RecipeCategory.new(
        name: params[:new_category][:name],
        display_order: params[:new_category][:display_order] || RecipeCategory.where(user_id: current_user.id).count + 1,
        user_id: current_user.id
      )
      category.save

      if category.persisted?
        # Use the new category for the recipe
        params[:recipe][:recipe_category_id] = category.id
      else
        # Return errors if category creation failed
        respond_to do |format|
          format.html {
            @recipe_categories = current_user.recipe_categories.order(:name)
            flash.now[:alert] = "Failed to create category: #{category.errors.full_messages.join(', ')}"
            render :new
          }
          format.json { render json: { status: 'error', errors: category.errors.full_messages }, status: :unprocessable_entity }
        end
        return
      end
    end

    @recipe = current_user.recipes.build(recipe_params)

    # If we get raw_text, parse it for possible ingredients
    parsed_data = {}
    if params[:raw_text].present?
      parsed_data = RecipeParserService.new(params[:raw_text]).parse
    end

    respond_to do |format|
      if @recipe.save
        format.html { redirect_to @recipe, notice: 'Recipe was successfully created.' }
        format.json {
          render json: {
            status: 'success',
            message: 'Recipe was successfully created.',
            recipe: {
              id: @recipe.id,
              name: @recipe.name,
              instructions: @recipe.instructions,
              notes: @recipe.notes,
              category: @recipe.recipe_category.name,
              parsed_ingredients: parsed_data[:ingredients]
            }
          }, status: :created
        }
      else
        format.html {
          @recipe_categories = current_user.recipe_categories.order(:name)
          render :new
        }
        format.json { render json: { status: 'error', errors: @recipe.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: 'Recipe was successfully updated.' }
        format.json { render json: { status: 'success', message: 'Recipe was successfully updated.' } }
      else
        format.html {
          @recipe_categories = current_user.recipe_categories.order(:name)
          render :edit
        }
        format.json { render json: { status: 'error', errors: @recipe.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @recipe.destroy
    respond_to do |format|
      format.html { redirect_to recipes_url, notice: 'Recipe was successfully deleted.' }
      format.json { render json: { status: 'success', message: 'Recipe was successfully deleted.' } }
    end
  end

  def mark_completed
    @recipe.update(completed: true, completed_at: Time.current)
    respond_to do |format|
      format.html { redirect_to @recipe, notice: 'Recipe marked as completed.' }
      format.json { render json: { status: 'success', message: 'Recipe marked as completed.' } }
    end
  end

  def mark_incomplete
    @recipe.update(completed: false, completed_at: nil)
    respond_to do |format|
      format.html { redirect_to @recipe, notice: 'Recipe marked as incomplete.' }
      format.json { render json: { status: 'success', message: 'Recipe marked as incomplete.' } }
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