require 'rails_helper'

RSpec.describe RecipeServices::Parser do
  describe '#initialize' do
    it 'normalizes unicode fractions' do
      text = "½ cup sugar and ¼ cup flour with ⅔ cup milk"
      parser = RecipeServices::Parser.new(text)

      expect(parser.raw_text).to eq("1/2 cup sugar and 1/4 cup flour with 2/3 cup milk")
    end
  end

  describe '#parse_ingredients' do
    it 'parses a simple list of ingredients' do
      text = "2 cups flour\n1 tsp salt\n1/2 cup sugar"
      parser = RecipeServices::Parser.new(text)

      result = parser.parse_ingredients
      expect(result[:ingredients].size).to eq(3)
      expect(result[:ingredients][0][:name]).to eq("flour")
      expect(result[:ingredients][0][:quantity]).to eq(2.0)
      expect(result[:ingredients][0][:unit_name]).to eq("cup")
      expect(result[:ingredients][1][:name]).to eq("salt")
      expect(result[:ingredients][1][:quantity]).to eq(1.0)
      expect(result[:ingredients][1][:unit_name]).to eq("teaspoon")
      expect(result[:ingredients][2][:name]).to eq("sugar")
      expect(result[:ingredients][2][:quantity]).to eq(0.5)
      expect(result[:ingredients][2][:unit_name]).to eq("cup")
    end

    it 'parses ingredients with preparation methods' do
      text = "2 cups flour, sifted\n1 onion, diced\n3 cloves garlic, minced"
      parser = RecipeServices::Parser.new(text)

      result = parser.parse_ingredients
      expect(result[:ingredients].size).to eq(3)
      expect(result[:ingredients][1][:name]).to eq("onion")
      expect(result[:ingredients][1][:preparation]).to eq("diced")
      expect(result[:ingredients][2][:name]).to eq("garlic")
      expect(result[:ingredients][2][:preparation]).to eq("minced")
    end

    it 'parses ingredients with size information' do
      text = "1 large onion\n2 medium potatoes\n3 small carrots"
      parser = RecipeServices::Parser.new(text)

      result = parser.parse_ingredients
      expect(result[:ingredients].size).to eq(3)
      expect(result[:ingredients][0][:name]).to eq("onion")
      expect(result[:ingredients][0][:size]).to eq("large")
      expect(result[:ingredients][1][:name]).to eq("potatoes")
      expect(result[:ingredients][1][:size]).to eq("medium")
      expect(result[:ingredients][2][:name]).to eq("carrots")
      expect(result[:ingredients][2][:size]).to eq("small")
    end

    it 'extracts notes about alternative ingredients' do
      text = "1 cup honey or maple syrup\n2 tbsp butter or coconut oil"
      parser = RecipeServices::Parser.new(text)

      result = parser.parse_ingredients
      expect(result[:ingredients].size).to eq(2)
      expect(result[:notes].size).to eq(2)
      expect(result[:notes].first).to include("maple syrup instead of cup honey")
      expect(result[:notes].last).to include("coconut oil instead of tbsp butter")
    end

    it 'handles unicode fractions in ingredient quantities' do
      text = "½ cup sugar\n¼ cup flour\n⅔ cup milk"
      parser = RecipeServices::Parser.new(text)

      result = parser.parse_ingredients
      expect(result[:ingredients].size).to eq(3)
      expect(result[:ingredients][0][:quantity]).to eq(0.5)
      expect(result[:ingredients][1][:quantity]).to eq(0.25)
      expect(result[:ingredients][2][:quantity]).to eq(2.0/3.0)
    end

    it 'removes descriptors from ingredient names' do
      text = "2 cups freshly milled flour\n1 tsp freshly ground black pepper\n3 tbsp fresh chopped parsley"
      parser = RecipeServices::Parser.new(text)

      result = parser.parse_ingredients
      expect(result[:ingredients][0][:name]).to eq("milled flour")
      expect(result[:ingredients][0][:name]).not_to include("freshly")
      expect(result[:ingredients][1][:name]).to eq("black pepper")
      expect(result[:ingredients][1][:name]).not_to include("freshly")
      expect(result[:ingredients][2][:name]).to eq("parsley")
      expect(result[:ingredients][2][:name]).not_to include("fresh")
      expect(result[:ingredients][2][:preparation]).to eq("chopped")
    end

    it 'handles empty lines in the ingredient list' do
      text = "2 cups flour\n\n1 tsp salt\n\n1/2 cup sugar"
      parser = RecipeServices::Parser.new(text)

      result = parser.parse_ingredients
      expect(result[:ingredients].size).to eq(3)
    end

    it 'falls back to simple parsing when Ingreedy fails' do
      # Create a scenario where Ingreedy would likely fail
      text = "some weird ingredient description that Ingreedy can't parse"
      parser = RecipeServices::Parser.new(text)

      # Mock the Ingreedy failure
      allow(Ingreedy).to receive(:parse).and_raise(StandardError.new("Ingreedy error"))

      result = parser.parse_ingredients
      expect(result[:ingredients].size).to eq(1)
      # Default values when parsing fails
      expect(result[:ingredients][0][:quantity]).to eq(1.0)
      expect(result[:ingredients][0][:unit_name]).to eq("whole")
    end
  end

  describe 'edge cases' do
    it 'handles completely empty input' do
      parser = RecipeServices::Parser.new("")

      result = parser.parse_ingredients
      expect(result[:ingredients]).to be_empty
      expect(result[:notes]).to be_empty
    end

    it 'handles input with only whitespace' do
      parser = RecipeServices::Parser.new("  \n  \t  ")

      result = parser.parse_ingredients
      expect(result[:ingredients]).to be_empty
      expect(result[:notes]).to be_empty
    end

    it 'handles input with all unicode fractions' do
      text = "½ ¼ ⅓ ⅔ ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ ⅛ ⅜ ⅝ ⅞"
      parser = RecipeServices::Parser.new(text)

      expect(parser.raw_text).to eq("1/2 1/4 1/3 2/3 1/5 2/5 3/5 4/5 1/6 5/6 1/8 3/8 5/8 7/8")
    end
  end
end
