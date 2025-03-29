class GroceriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_grocery, only: [ :show, :update, :destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from StandardError, with: :handle_unexpected_error

  def index
    @groceries = current_user.groceries.includes(:grocery_section, :unit)
    @grocery_sections = current_user.grocery_sections.order(display_order: :asc)
    @grouped_groceries = GroceryPresenter.grouped_groceries(@groceries, @grocery_sections)
    @units = Unit.all.order(name: :asc)

    respond_to do |format|
      format.html # This will render your index.html.erb
      format.json { render json: @grouped_groceries }
    end
  end

  def show
    @grocery = current_user.groceries.includes(:unit, :grocery_section).find(params[:id])
    @grocery_sections = current_user.grocery_sections.order(display_order: :asc)
    @units = Unit.all.order(name: :asc)

    @grocery_data = @grocery.as_json(include: {
      unit: { only: [ :id, :name ] },
      grocery_section: { only: [ :id, :name ] }
    })

    respond_to do |format|
      format.html
      format.json {
        render json: {
          grocery: @grocery_data,
          grocery_sections: @grocery_sections,
          units: @units
        }
      }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to groceries_path, alert: "Grocery not found" }
      format.json { render json: { error: "Grocery not found" }, status: :not_found }
    end
  end

  def create
    Rails.logger.info("Received grocery params: #{grocery_params}")
    Rails.logger.info("Received new section params: #{new_section_params}") if params[:new_section].present?

    creator = ::GroceryServices::Creator.new(
      current_user,
      grocery_params.to_h,
      params[:new_section].present? ? new_section_params.to_h : nil
    )

    if creator.call
      # Include grocery section name in the response
      grocery_with_section = creator.grocery.as_json
      grocery_with_section["grocery_section"] = {
        name: creator.grocery.grocery_section&.name
      }

      render json: grocery_with_section, status: :created
    else
      Rails.logger.warn("Creation failed: #{creator.error_messages}")
      render json: {
        error: creator.error_messages,
        details: {}
      }, status: :unprocessable_entity
    end
  end

  def update
    if @grocery.update(grocery_params)
      # Return full grocery data with associated objects, just like in the show method
      grocery_data = @grocery.as_json(include: {
        unit: { only: [ :id, :name ] },
        grocery_section: { only: [ :id, :name ] }
      })
      render json: grocery_data
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
      format.html { redirect_to groceries_path, alert: "Grocery not found" }
      format.json { render json: { error: "Grocery not found" }, status: :not_found }
    end
  end

  def grocery_params
    params.require(:grocery).permit(
      :quantity,
      :name,
      :unit_id,
      :grocery_section_id,
      :emoji
    )
  end

  def new_section_params
    params.require(:new_section).permit(:name, :display_order)
  end

  def render_error(errors)
    render json: { error: errors.full_messages.join(", ") },
           status: :unprocessable_entity
  end

  def record_not_found
    render json: { error: "Grocery not found" }, status: :not_found
  end

  def handle_unexpected_error(exception)
    Rails.logger.error("Unexpected error: #{exception.message}")
    render json: { error: "An unexpected error occurred" },
           status: :internal_server_error
  end
end
