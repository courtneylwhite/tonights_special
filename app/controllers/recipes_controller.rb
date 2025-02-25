class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [ :show, :update, :destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from StandardError, with: :handle_unexpected_error

  def index
    @recipes = current_user.recipes.includes(:recipe_category)

    respond_to do |format|
      format.html
      format.json { render json: @recipes }
    end
  end

  def show
  end

  def create
  end

  def update
  end

  def destroy
  end
end
