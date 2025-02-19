class GroceriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_grocery, only: [:show, :update, :destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from StandardError, with: :handle_unexpected_error

  def index
    @groceries = current_user.groceries.includes(:grocery_section, :unit)
    @grouped_groceries = GroceryPresenter.grouped_groceries(@groceries)

    respond_to do |format|
      format.html # This will render your index.html.erb
      format.json { render json: @grouped_groceries }
    end
  end

  def show
    @grocery = current_user.groceries.includes(:unit).find(params[:id])
    @grocery_data = @grocery.as_json(include: { unit: { only: [:name] } })
    respond_to do |format|
      format.html
      format.json { render json: @grocery }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to groceries_path, alert: 'Grocery not found' }
      format.json { render json: { error: 'Grocery not found' }, status: :not_found }
    end
  end

  def create
    @grocery = current_user.groceries.build(grocery_params)

    if @grocery.save
      render json: @grocery, status: :created
    else
      render json: { error: @grocery.errors.full_messages.join(', ') },
             status: :unprocessable_entity
    end
  end

  def update
    if @grocery.update(grocery_params)
      render json: @grocery
    else
      render_error(@grocery.errors)
    end
  end

  def destroy
    @grocery.destroy
    head :no_content
  end

  private

  def set_grocery
    @grocery = current_user.groceries.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to groceries_path, alert: 'Grocery not found' }
      format.json { render json: { error: 'Grocery not found' }, status: :not_found }
    end
  end

  def grocery_params
    params.require(:grocery).permit(
      :quantity,
      :name,
      :unit_id,
      :grocery_section_id,
      :store_section_id,
      :emoji
    )
  end

  def render_error(errors)
    render json: { error: errors.full_messages.join(', ') },
           status: :unprocessable_entity
  end

  def record_not_found
    render json: { error: 'Grocery not found' }, status: :not_found
  end

  def handle_unexpected_error(exception)
    Rails.logger.error("Unexpected error: #{exception.message}")
    render json: { error: 'An unexpected error occurred' },
           status: :internal_server_error
  end
end
