require 'rails_helper'

RSpec.describe GroceryMatcher do
  # Create shared resources once for all tests
  let(:user) { create(:user) }
  let(:grocery_section) { create(:grocery_section, user: user) }
  let(:unit) { create(:unit, name: 'Piece', abbreviation: 'pc', category: 'count') }

  # Create a single recipe category per user to reuse
  let(:recipe_category) { create(:recipe_category, user: user, name: "TestCategory-#{user.id}") }

  describe '.find_grocery_by_name' do
    context 'with exact match' do
      it 'finds grocery with exact name match' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Tomato',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Tomato')
        expect(result).to eq(grocery)
      end

      it 'is case insensitive' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Tomato',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'tOmAtO')
        expect(result).to eq(grocery)
      end

      it 'trims whitespace' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Tomato',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, '  Tomato  ')
        expect(result).to eq(grocery)
      end
    end

    context 'with plural/singular match' do
      it 'finds singular form when given plural' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Tomato',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Tomatoes')
        expect(result).to eq(grocery)
      end

      it 'finds plural form when given singular' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Tomatoes',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Tomato')
        expect(result).to eq(grocery)
      end

      it 'handles words ending in "y" correctly' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Berry',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Berries')
        expect(result).to eq(grocery)
      end

      it 'handles words ending in special patterns correctly' do
        groceries = {
          'Dish' => 'Dishes',
          'Box' => 'Boxes',
          'Buzz' => 'Buzzes'
        }

        groceries.each do |singular, plural|
          grocery = create(:grocery,
                           user: user,
                           grocery_section: grocery_section,
                           unit: unit,
                           name: singular,
                           quantity: 1
          )

          result = GroceryMatcher.find_grocery_by_name(user, plural)
          expect(result).to eq(grocery)
        end
      end
    end

    context 'with prefix/containment match' do
      it 'finds grocery when ingredient name is a prefix' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Tomato Sauce',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Tomato')
        expect(result).to eq(grocery)
      end

      it 'finds grocery when ingredient name is contained within grocery name' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Diced Tomatoes',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Tomato')
        expect(result).to eq(grocery)
      end

      it 'finds grocery when grocery name is a prefix of ingredient name' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Milk',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Milk Chocolate')
        expect(result).to eq(grocery)
      end
    end

    context 'with meat type matching' do
      it 'matches based on meat type' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Chicken Breast',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Chicken')
        expect(result).to eq(grocery)
      end

      it 'uses descriptive words to narrow down meat type' do
        grocery1 = create(:grocery,
                          user: user,
                          grocery_section: grocery_section,
                          unit: unit,
                          name: 'Ground Beef',
                          quantity: 1
        )

        grocery2 = create(:grocery,
                          user: user,
                          grocery_section: grocery_section,
                          unit: unit,
                          name: 'Beef Steak',
                          quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Ground Beef')
        expect(result).to eq(grocery1)
      end

      it 'identifies correct meat type in a longer description' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Salmon Fillet',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Fresh Salmon with Herbs')
        expect(result).to eq(grocery)
      end
    end

    context 'with multi-word matching' do
      it 'matches based on significant words' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Red Bell Pepper',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Bell Pepper')
        expect(result).to eq(grocery)
      end

      it 'ignores common words when matching' do
        grocery = create(:grocery,
                         user: user,
                         grocery_section: grocery_section,
                         unit: unit,
                         name: 'Pasta with Sauce',
                         quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Pasta and Sauce')
        expect(result).to eq(grocery)
      end

      it 'scores matches by number of matching words' do
        grocery1 = create(:grocery,
                          user: user,
                          grocery_section: grocery_section,
                          unit: unit,
                          name: 'Chocolate Chip Cookies',
                          quantity: 1
        )

        grocery2 = create(:grocery,
                          user: user,
                          grocery_section: grocery_section,
                          unit: unit,
                          name: 'Chocolate Bar',
                          quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Chocolate Chip')
        expect(result).to eq(grocery1)
      end
    end

    context 'with multiple matching strategies' do
      it 'tries strategies in order until a match is found' do
        # Will match by exact match
        grocery1 = create(:grocery,
                          user: user,
                          grocery_section: grocery_section,
                          unit: unit,
                          name: 'Onion',
                          quantity: 1
        )

        # Would match by prefix containment, but exact match takes precedence
        grocery2 = create(:grocery,
                          user: user,
                          grocery_section: grocery_section,
                          unit: unit,
                          name: 'Onion Powder',
                          quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Onion')
        expect(result).to eq(grocery1)
      end

      it 'returns nil when no match is found' do
        create(:grocery,
               user: user,
               grocery_section: grocery_section,
               unit: unit,
               name: 'Carrot',
               quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Zucchini')
        expect(result).to be_nil
      end
    end

    context 'with user scoping' do
      it 'only matches groceries belonging to the given user' do
        user2 = create(:user)

        grocery1 = create(:grocery,
                          user: user,
                          grocery_section: grocery_section,
                          unit: unit,
                          name: 'Apple',
                          quantity: 1
        )

        grocery2 = create(:grocery,
                          user: user2,
                          grocery_section: create(:grocery_section, user: user2),
                          unit: unit,
                          name: 'Apple',
                          quantity: 1
        )

        result = GroceryMatcher.find_grocery_by_name(user, 'Apple')
        expect(result).to eq(grocery1)

        result2 = GroceryMatcher.find_grocery_by_name(user2, 'Apple')
        expect(result2).to eq(grocery2)
      end
    end
  end

  describe '.update_related_ingredients' do
    # Generate a unique recipe name for each test within this describe block
    let(:recipe_name) { "Recipe-#{SecureRandom.hex(8)}" }
    let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category, name: recipe_name) }

    it 'updates recipe ingredients with matching names' do
      grocery = create(:grocery,
                       user: user,
                       grocery_section: grocery_section,
                       unit: unit,
                       name: 'Sugar',
                       quantity: 1
      )

      ingredient = create(:recipe_ingredient,
                          recipe: recipe,
                          unit: unit,
                          name: 'Sugar',
                          quantity: 2,
                          grocery_id: nil
      )

      expect {
        GroceryMatcher.update_related_ingredients(grocery)
      }.to change { ingredient.reload.grocery_id }.from(nil).to(grocery.id)
    end

    it 'updates recipe ingredients containing the grocery name' do
      grocery = create(:grocery,
                       user: user,
                       grocery_section: grocery_section,
                       unit: unit,
                       name: 'Salt',
                       quantity: 1
      )

      ingredient = create(:recipe_ingredient,
                          recipe: recipe,
                          unit: unit,
                          name: 'Sea Salt',
                          quantity: 2,
                          grocery_id: nil
      )

      expect {
        GroceryMatcher.update_related_ingredients(grocery)
      }.to change { ingredient.reload.grocery_id }.from(nil).to(grocery.id)
    end

    it 'does not update ingredients that already have a grocery_id' do
      grocery1 = create(:grocery,
                        user: user,
                        grocery_section: grocery_section,
                        unit: unit,
                        name: 'Flour',
                        quantity: 1
      )

      grocery2 = create(:grocery,
                        user: user,
                        grocery_section: grocery_section,
                        unit: unit,
                        name: 'All-Purpose Flour',
                        quantity: 1
      )

      ingredient = create(:recipe_ingredient,
                          recipe: recipe,
                          unit: unit,
                          name: 'Flour',
                          quantity: 2,
                          grocery_id: grocery1.id
      )

      expect {
        GroceryMatcher.update_related_ingredients(grocery2)
      }.not_to change { ingredient.reload.grocery_id }
    end

    it 'only updates ingredients for recipes belonging to the grocery owner' do
      user2 = create(:user)
      # Create a separate category for user2
      recipe_category2 = create(:recipe_category, user: user2, name: "TestCategory-#{user2.id}")
      # Create a recipe for user2 with a unique name
      recipe2 = create(:recipe, user: user2, recipe_category: recipe_category2, name: "User2Recipe-#{SecureRandom.hex(8)}")

      grocery = create(:grocery,
                       user: user,
                       grocery_section: grocery_section,
                       unit: unit,
                       name: 'Butter',
                       quantity: 1
      )

      ingredient1 = create(:recipe_ingredient,
                           recipe: recipe,
                           unit: unit,
                           name: 'Butter',
                           quantity: 2,
                           grocery_id: nil
      )

      ingredient2 = create(:recipe_ingredient,
                           recipe: recipe2,
                           unit: unit,
                           name: 'Butter',
                           quantity: 2,
                           grocery_id: nil
      )

      expect {
        GroceryMatcher.update_related_ingredients(grocery)
      }.to change { ingredient1.reload.grocery_id }.from(nil).to(grocery.id)

      expect(ingredient2.reload.grocery_id).to be_nil
    end
  end
end
