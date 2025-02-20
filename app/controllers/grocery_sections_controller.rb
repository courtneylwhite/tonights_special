class GrocerySectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_grocery_section, only: [ :destroy ]

  def create
    @grocery_section = GrocerySection.new(grocery_section_params)

    if @grocery_section.save
      render json: @grocery_section, status: :created
    else
      render json: { errors: @grocery_section.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
  end

  private

  def set_grocery_section
    @grocery_section = GrocerySection.find(params[:id])
  end

  def grocery_section_params
    params.require(:grocery_section).permit(:name, :display_order)
  end
end
