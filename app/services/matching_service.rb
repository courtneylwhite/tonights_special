class MatchingService
  class << self
    def match_ingredient_to_grocery(user, name)
      normalized_name = normalize_name(name)
      # Matching strategy in order of preference:
      exact_match = exact_match(user, normalized_name)
      return exact_match if exact_match

      variation_match = singular_plural_match(user, normalized_name)
      return variation_match if variation_match

      parent_match = parent_ingredient_match(user, normalized_name)
      return parent_match if parent_match

      fuzzy_matches = fuzzy_match(user, normalized_name)
      fuzzy_matches.first
    end

    def match_grocery_to_ingredients(grocery)
      user_id = grocery.user_id
      grocery_name = normalize_name(grocery.name)
      ingredients_to_update = find_matching_ingredients(user_id, grocery_name)
      update_count = ingredients_to_update.update_all(grocery_id: grocery.id)

      {
        grocery_id: grocery.id,
        grocery_name: grocery_name,
        matched_ingredients: update_count
      }
    end

    def batch_match_ingredients(recipe_id)
      # This method now simply enqueues a job instead of doing the work directly
      ::RecipeBatchMatchingJob.perform_async(recipe_id)
    end

    private

    def normalize_name(name)
      name.to_s.downcase.strip
    end

    def exact_match(user, name)
      user.groceries.where("LOWER(name) = ?", name).first
    end

    def singular_plural_match(user, name)
      singular = name.gsub(/ies$/, "y").gsub(/es$/, "").gsub(/s$/, "")
      plural = if name.end_with?("y")
                 name.chomp("y") + "ies"
      elsif name.end_with?("ch", "sh", "ss", "x", "z")
                 name + "es"
      else
                 name + "s"
      end

      user.groceries.where("LOWER(name) = ? OR LOWER(name) = ?", singular, plural).first
    end

    def parent_ingredient_match(user, name)
      adjectives = %w[fresh frozen dried ground minced chopped diced sliced
                    unsalted salted low-fat non-fat whole organic]

      words = name.split(/\s+/)
      return nil if words.size <= 1

      base_words = words.reject { |word| adjectives.include?(word) }
      return nil if base_words.empty?

      base_ingredient = base_words.last
      user.groceries.where("LOWER(name) = ?", base_ingredient).first
    end

    def fuzzy_match(user, name)
      user.groceries.similar_to(name)
    end

    def find_matching_ingredients(user_id, grocery_name)
      RecipeIngredient.joins(:recipe)
                      .where(recipes: { user_id: user_id })
                      .where(grocery_id: nil)
                      .where("LOWER(recipe_ingredients.name) = ? OR " +
                               "LOWER(recipe_ingredients.name) LIKE ?",
                             grocery_name, "%#{grocery_name}%")
    end
  end
end
