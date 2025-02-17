class GroceriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @groceries = current_user.groceries
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
