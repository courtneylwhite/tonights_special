class GroceryMatcher
  class << self
    def find_grocery_by_name(user, name)
      # Initialize configuration
      GroceryMatcherConfig.default_config if GroceryMatcherConfig.ignore_words.nil?

      # Convert to lowercase for comparison
      name_downcase = name.downcase.strip

      # Apply configured matching strategies
      GroceryMatcherConfig.matching_strategies.each do |strategy|
        result = send("match_by_#{strategy}", user, name_downcase)
        return result if result
      end

      # No match found
      nil
    end

    def update_related_ingredients(grocery)
      # Explicitly specify the table for column references
      ingredients_to_update = RecipeIngredient.joins(:recipe)
                                              .where(recipes: { user_id: grocery.user_id })
                                              .where("LOWER(recipe_ingredients.name) = ?", grocery.name.downcase)
                                              .or(RecipeIngredient.joins(:recipe)
                                                                  .where(recipes: { user_id: grocery.user_id })
                                                                  .where("LOWER(recipe_ingredients.name) LIKE ?", "%#{grocery.name.downcase}%"))
                                              .where(grocery_id: nil)

      # Update all matching ingredients with the grocery's ID
      ingredients_to_update.update_all(grocery_id: grocery.id)
    end

    private

    def match_by_exact_match(user, name_downcase)
      Grocery.where(user_id: user.id)
             .where("LOWER(name) = ?", name_downcase)
             .first
    end

    def match_by_plural_singular(user, name_downcase)
      # Existing plural/singular logic
      singular_name = name_downcase.gsub(/ies$/, "y")
                                   .gsub(/es$/, "")
                                   .gsub(/s$/, "")

      plural_name = if name_downcase.end_with?("y")
                      name_downcase.chomp("y") + "ies"
      elsif name_downcase.end_with?("ch", "sh", "ss", "x", "z")
                      name_downcase + "es"
      else
                      name_downcase + "s"
      end

      Grocery.where(user_id: user.id)
             .where("LOWER(name) = ? OR LOWER(name) = ?", singular_name, plural_name)
             .first
    end

    def match_by_prefix_containment(user, name_downcase)
      Grocery.where(user_id: user.id)
             .where("LOWER(name) LIKE ? OR LOWER(name) LIKE ? OR ? LIKE CONCAT(LOWER(name), '%')",
                    "#{name_downcase}%",
                    "%#{name_downcase}%",
                    name_downcase)
             .first
    end

    def match_by_meat_type_matching(user, name_downcase)
      words = name_downcase.split(/[\s,\-\/]+/)
      meat_type = words.find { |w| GroceryMatcherConfig.meat_types.include?(w) }

      return nil unless meat_type

      meat_groceries = Grocery.where(user_id: user.id)
                              .where("LOWER(name) LIKE ?", "%#{meat_type}%")

      # If we have other descriptive words, use them to narrow down
      if words.length > 1
        descriptors = words - [ meat_type ]

        best_matches = meat_groceries.select do |g|
          descriptors.any? { |d| g.name.downcase.include?(d) }
        end

        return best_matches.first if best_matches.any?
      end

      meat_groceries.first
    end

    def match_by_multi_word_matching(user, name_downcase)
      words = name_downcase.split(/[\s,\-\/]+/)
      return nil unless words.length > 1 && words.any? { |w| w.length > 2 }

      # Filter out common words
      filtered_words = words.reject { |w| w.length <= 2 || GroceryMatcherConfig.ignore_words.include?(w) }

      return nil unless filtered_words.any?

      # Try to match each significant word
      sql_conditions = filtered_words.map { |w| "LOWER(name) LIKE ?" }.join(" OR ")
      sql_params = filtered_words.map { |w| "%#{w}%" }

      word_matches = Grocery.where(user_id: user.id)
                            .where(sql_conditions, *sql_params)

      return nil unless word_matches.count > 0

      # Score and find the best match
      word_matches.max_by do |g|
        grocery_words = g.name.downcase.split(/[\s,\-\/]+/)
        matching_words = filtered_words & grocery_words

        # Base score is the number of matching words
        score = matching_words.size * 10

        # Bonus for matching words in the same order
        matching_indices_ingredient = matching_words.map { |w| filtered_words.index(w) }
        matching_indices_grocery = matching_words.map { |w| grocery_words.index(w) }

        if matching_indices_ingredient.sort == matching_indices_ingredient &&
          matching_indices_grocery.sort == matching_indices_grocery
          score += 5
        end

        # Bonus for matching the first word
        score += 3 if grocery_words.first == filtered_words.first

        score
      end
    end
  end
end
