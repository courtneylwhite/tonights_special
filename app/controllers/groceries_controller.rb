class GroceriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @groceries = current_user.groceries.includes(:grocery_section, :unit)  # Change to instance variable
    @grouped_groceries = @groceries.map do |grocery|
      {
        id: grocery.id,
        name: grocery.name,
        quantity: grocery.quantity,
        unit: grocery.unit.abbreviation,
        emoji: grocery.emoji,
        category: grocery.grocery_section.name
      }
    end.group_by { |g| g.delete(:category) }
  end

  def show
    @grocery = Grocery.find(params[:id])
  end

  def create
  end

  def update
  end

  def destroy
  end
end
