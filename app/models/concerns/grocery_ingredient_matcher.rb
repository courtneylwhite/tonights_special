module GroceryIngredientMatcher
  extend ActiveSupport::Concern

  included do
    after_save :update_related_ingredients
  end

  private

  def update_related_ingredients
    # Use the GroceryMatcher to update related ingredients
    GroceryMatcher.update_related_ingredients(self)
  end
end
