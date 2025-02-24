class GroceriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_grocery, only: [ :show, :update, :destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from StandardError, with: :handle_unexpected_error

  def index
    @groceries = current_user.groceries.includes(:grocery_section, :unit)
    @grocery_sections = current_user.grocery_sections.order(display_order: :asc)
    @grouped_groceries = GroceryPresenter.grouped_groceries(@groceries, @grocery_sections)
    @units = Unit.all

    respond_to do |format|
      format.html # This will render your index.html.erb
      format.json { render json: @grouped_groceries }
    end
  end

  def show
    @grocery = current_user.groceries.includes(:unit).find(params[:id])
    @grocery_data = @grocery.as_json(include: { unit: { only: [ :name ] } })
    respond_to do |format|
      format.html
      format.json { render json: @grocery }
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

    ActiveRecord::Base.transaction do
      # Create a new section if one was submitted
      if params[:new_section].present?
        section_params = new_section_params
        section_params[:display_order] ||= current_user.grocery_sections.count + 1

        @section = current_user.grocery_sections.build(section_params)
        unless @section.save
          Rails.logger.warn("Section validation failed: #{@section.errors.full_messages.join(', ')}")
          render json: {
            error: @section.errors.full_messages.join(", "),
            details: @section.errors.details
          }, status: :unprocessable_entity
          return
        end

        # Use the newly created section's ID for the grocery
        modified_params = grocery_params.to_h
        modified_params[:grocery_section_id] = @section.id
      else
        modified_params = grocery_params
      end

      @grocery = current_user.groceries.build(modified_params)

      if @grocery.save
        render json: @grocery, status: :created
      else
        Rails.logger.warn("Validation failed: #{@grocery.errors.full_messages.join(', ')}")
        # Rollback the transaction if the grocery couldn't be saved
        raise ActiveRecord::Rollback
        render json: {
          error: @grocery.errors.full_messages.join(", "),
          details: @grocery.errors.details
        }, status: :unprocessable_entity
      end
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