class GrocerySectionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @grocery_section = current_user.grocery_sections.build(grocery_section_params)

    if @grocery_section.save
      render json: @grocery_section, status: :created
    else
      render json: { errors: @grocery_section.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    @grocery_sections = current_user.grocery_sections.order(display_order: :asc)

    respond_to do |format|
      format.json { render json: @grocery_sections }
    end
  end

  private

  def set_grocery_section
    @grocery_section = GrocerySection.find(params[:id])
  end

  def grocery_section_params
    params.require(:grocery_section).permit(:name, :display_order)
  end
end
