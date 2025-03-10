require 'rails_helper'

RSpec.describe MatchingService do
  let(:user) { create(:user) }
  let(:grocery_section) { create(:grocery_section, user: user) }
  let(:unit) { create(:unit) }

  describe '.match_grocery_to_ingredients' do
    let(:recipe_category) { create(:recipe_category, user: user) }
    let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }
    let(:unit) { create(:unit) }
    let(:grocery) {
      create(:grocery,
             user: user,
             name: 'apple',
             grocery_section: create(:grocery_section, user: user, name: "Unique Section #{rand(1000)}"),
             unit: unit,
             quantity: 1
      )
    }

    let!(:recipe_ingredient1) {
      create(:recipe_ingredient,
             recipe: recipe,
             name: 'Apple',
             grocery_id: nil,
             quantity: 1,
             unit: unit
      )
    }
    let!(:recipe_ingredient2) {
      create(:recipe_ingredient,
             recipe: recipe,
             name: 'apple',
             grocery_id: nil,
             quantity: 1,
             unit: unit
      )
    }
    let!(:recipe_ingredient3) {
      create(:recipe_ingredient,
             recipe: recipe,
             name: 'green apple',
             grocery_id: nil,
             quantity: 1,
             unit: unit
      )
    }

    it 'updates matching ingredients with grocery id' do
      result = MatchingService.match_grocery_to_ingredients(grocery)

      # Reload to check actual database state
      matching_ingredients = RecipeIngredient.joins(:recipe)
                                             .where(recipes: { user_id: user.id }, grocery_id: nil)
                                             .where("LOWER(recipe_ingredients.name) = ? OR LOWER(recipe_ingredients.name) LIKE ?",
                                                    'apple', '%apple%')

      expect(result).to include(
                          grocery_id: grocery.id,
                          grocery_name: 'apple',
                          matched_ingredients: matching_ingredients.count
                        )

      # Verify that the ingredients were actually updated
      matching_ingredients.reload.each do |ingredient|
        expect(ingredient.grocery_id).to eq(grocery.id)
      end
    end
  end
end
