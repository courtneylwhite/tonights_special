module GroceryIngredientMatcher
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    after_save :match_with_recipe_ingredients

    pg_search_scope :similar_to,
                    against: :name,
                    using: {
                      tsearch: { dictionary: "english", prefix: true },
                      trigram: { threshold: 0.3 }
                    }
  end

  def match_with_recipe_ingredients
    MatchingService.match_grocery_to_ingredients(self)
  end
end
