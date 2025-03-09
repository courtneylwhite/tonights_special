module RecipeServices
  class Category
    attr_reader :user, :params

    def initialize(user, params)
      @user = user
      @params = params
    end

    def create_new_category
      return nil unless params[:name].present?

      existing_display_order = RecipeCategory.where(
        user_id: user.id,
        display_order: params[:display_order] || RecipeCategory.where(user_id: user.id).count + 1
      ).exists?

      # If there's a conflict, use max + 1
      display_order = if existing_display_order
                        RecipeCategory.where(user_id: user.id).maximum(:display_order).to_i + 1
      else
                        params[:display_order] || RecipeCategory.where(user_id: user.id).count + 1
      end

      category = RecipeCategory.new(
        name: params[:name],
        display_order: display_order,
        user_id: user.id
      )

      if category.save
        { success: true, category: category }
      else
        { success: false, errors: category.errors.full_messages }
      end
    end
  end
end
