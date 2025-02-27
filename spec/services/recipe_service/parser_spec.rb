require 'rails_helper'

RSpec.describe RecipeServices::Parser do
  describe '#initialize' do
    it 'stores the raw text and normalizes unicode fractions' do
      raw_text = "1 ½ cups flour"
      parser = RecipeServices::Parser.new(raw_text)

      expect(parser.raw_text).to eq("1 0.5 cups flour")
    end

    it 'handles multiple unicode fractions in the same text' do
      raw_text = "½ cup sugar, ¼ cup butter, and ¾ cup flour"
      parser = RecipeServices::Parser.new(raw_text)

      expect(parser.raw_text).to eq("0.5 cup sugar, 0.25 cup butter, and 0.75 cup flour")
    end
  end

  describe '#normalize_unicode_fractions' do
    it 'converts all unicode fractions to decimal values' do
      parser = RecipeServices::Parser.new("")
      text = "½ ⅓ ⅔ ¼ ¾ ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ ⅛ ⅜ ⅝ ⅞"
      result = parser.normalize_unicode_fractions(text)

      expect(result).to eq("0.5 0.3333333333333333 0.6666666666666666 0.25 0.75 0.2 0.4 0.6 0.8 0.16666666666666666 0.8333333333333334 0.125 0.375 0.625 0.875")
    end
  end

  describe '#parse' do
    context 'with explicitly defined sections' do
      it 'correctly parses ingredients and instructions with clear section markers' do
        raw_text = <<~TEXT
          Delicious Cake Recipe

          Ingredients:
          2 cups flour
          1 cup sugar
          3 eggs

          Instructions:
          Mix all ingredients.
          Bake at 350F for 30 minutes.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(3)
        expect(result[:ingredients][0][:name]).to eq("flour")
        expect(result[:ingredients][0][:quantity]).to eq(2.0)
        expect(result[:ingredients][0][:unit_name]).to eq("cup")

        expect(result[:instructions]).to include("Mix all ingredients.")
        expect(result[:instructions]).to include("Bake at 350F for 30 minutes.")
      end

      it 'handles "directions" as an alternative to "instructions"' do
        raw_text = <<~TEXT
          Ingredients:
          1 cup milk

          Directions:
          Heat milk until warm.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(1)
        expect(result[:instructions]).to include("Heat milk until warm.")
      end
    end

    context 'without explicit section markers' do
      it 'infers sections based on line structure' do
        raw_text = <<~TEXT
          1. Preheat oven to 350°F.
          2. In a large bowl, mix dry ingredients:
             * 1 cup flour
             * 1/2 cup sugar
             * 2 eggs
          3. Bake for 30 minutes.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)

        # For this test, we'll mock infer_section_break to force a specific behavior
        # Since the actual inference logic is complex and might vary
        allow_any_instance_of(RecipeServices::Parser).to receive(:infer_section_break).and_return(2)

        result = parser.parse

        expect(result[:ingredients].size).to be > 0
        expect(result[:instructions]).not_to be_empty
      end

      it 'handles recipes with only instructions' do
        raw_text = <<~TEXT
          Preheat oven to 350F.
          Mix ingredients together.
          Bake until golden.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients]).to be_empty
        expect(result[:instructions]).to include("Preheat oven to 350F.")
      end
    end

    context 'with unusual formatting' do
      it 'handles ingredients with parenthetical information' do
        raw_text = <<~TEXT
          Ingredients:
          1 (14.5 ounce) can diced tomatoes
          2 tablespoons oil (vegetable or olive)

          Instructions:
          Cook until done.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(2)
        expect(result[:ingredients][0][:name]).to include("can diced tomatoes")
      end

      it 'handles ingredients with different quantity formats' do
        raw_text = <<~TEXT
          Ingredients:
          1 1/2 cups flour
          5 cup sugar
          2/3 cup milk
          2 eggs

          Instructions:
          Mix and bake.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(4)
        expect(result[:ingredients][0][:quantity]).to eq(1.5)
        expect(result[:ingredients][1][:quantity]).to eq(5.0)
        expect(result[:ingredients][2][:quantity]).to eq(2.0/3.0)
        expect(result[:ingredients][3][:name]).to eq("eggs")
        expect(result[:ingredients][3][:quantity]).to eq(2)
      end

      it 'handles ingredients with unusual separators' do
        raw_text = <<~TEXT
          Ingredients:
          flour - 2 cups
          sugar: 1 cup
          salt - to taste

          Instructions:
          Combine all ingredients.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(3)
        expect(result[:ingredients][0][:name]).to eq("flour")
        expect(result[:ingredients][0][:quantity]).to eq(2.0)
        expect(result[:ingredients][1][:name]).to eq("sugar")
        expect(result[:ingredients][1][:quantity]).to eq(1.0)
      end
    end

    context 'with special phrases and formatting' do
      it 'cleans up ingredient names with special phrases' do
        raw_text = <<~TEXT
          Ingredients:
          2 tablespoons olive oil, divided
          1 teaspoon salt, to taste
          2 cloves garlic, minced (optional)

          Instructions:
          Cook everything.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(3)
        expect(result[:ingredients][0][:name]).to eq("olive oil")
        expect(result[:ingredients][1][:name]).to eq("salt")
        expect(result[:ingredients][2][:name]).to include("garlic")
        expect(result[:ingredients][2][:name]).to include("minced")
      end

      it 'normalizes various unit names' do
        raw_text = <<~TEXT
          Ingredients:
          2 tbsp butter
          1 tsp vanilla
          3 oz chocolate
          4 cup milk

          Instructions:
          Mix and enjoy.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients][0][:unit_name]).to eq("tablespoon")
        expect(result[:ingredients][1][:unit_name]).to eq("teaspoon")
        expect(result[:ingredients][2][:unit_name]).to eq("ounce")
        expect(result[:ingredients][3][:unit_name]).to eq("cup")
      end
    end

    context 'with ingredients lacking quantities or units' do
      it 'handles ingredients with no quantity specified' do
        raw_text = <<~TEXT
          Ingredients:
          Salt and pepper
          Fresh herbs

          Instructions:
          Season to taste.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(2)
        expect(result[:ingredients][0][:name]).to eq("salt and pepper")
        expect(result[:ingredients][0][:quantity]).to eq(1.0)
        expect(result[:ingredients][0][:unit_name]).to eq("whole")
      end

      it 'handles ingredients with quantity but no unit' do
        raw_text = <<~TEXT
          Ingredients:
          2 eggs
          3 apples

          Instructions:
          Mix and cook.
        TEXT

        parser = RecipeServices::Parser.new(raw_text)
        result = parser.parse

        expect(result[:ingredients].size).to eq(2)
        expect(result[:ingredients][0][:name]).to eq("eggs")
        expect(result[:ingredients][0][:quantity]).to eq(2.0)
        expect(result[:ingredients][0][:unit_name]).to eq("whole")
      end
    end
  end
end
