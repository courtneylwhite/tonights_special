class GroceriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @groceries = current_user.groceries.includes(:grocery_section)  # Change to instance variable
    @grouped_groceries = @groceries.map do |grocery|
      {
        id: grocery.id,
        name: grocery.name,
        quantity: grocery.quantity,
        unit_id: grocery.unit_id,
        emoji: grocery.emoji,
        category: grocery.grocery_section.name
      }
    end.group_by { |g| g.delete(:category) }
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
