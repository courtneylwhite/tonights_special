# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts "Clearing existing data..."
UnitConversion.destroy_all
RecipeIngredient.destroy_all
Recipe.destroy_all
GroceryListItem.destroy_all
Grocery.destroy_all
Unit.destroy_all
GrocerySection.destroy_all
StoreSection.destroy_all
User.destroy_all

puts "Creating users..."
user = User.create!(
  email: 'demo@example.com',
  password: 'password123',
  password_confirmation: 'password123'
)

puts "Creating units..."
# Volume units
cup = Unit.create!(name: 'Cup', abbreviation: 'cup', category: 'volume')
tbsp = Unit.create!(name: 'Tablespoon', abbreviation: 'tbsp', category: 'volume')
tsp = Unit.create!(name: 'Teaspoon', abbreviation: 'tsp', category: 'volume')
fl_oz = Unit.create!(name: 'Fluid Ounce', abbreviation: 'fl oz', category: 'volume')
ml = Unit.create!(name: 'Milliliter', abbreviation: 'ml', category: 'volume')

# Weight units
pound = Unit.create!(name: 'Pound', abbreviation: 'lb', category: 'weight')
ounce = Unit.create!(name: 'Ounce', abbreviation: 'oz', category: 'weight')
gram = Unit.create!(name: 'Gram', abbreviation: 'g', category: 'weight')
kg = Unit.create!(name: 'Kilogram', abbreviation: 'kg', category: 'weight')

# Count units
piece = Unit.create!(name: 'Piece', abbreviation: 'pc', category: 'count')
dozen = Unit.create!(name: 'Dozen', abbreviation: 'doz', category: 'count')

puts "Creating unit conversions..."
UnitConversion.create!([
     # Volume conversions
     { from_unit: cup, to_unit: ml, conversion_factor: 236.588 },
     { from_unit: tbsp, to_unit: ml, conversion_factor: 14.787 },
     { from_unit: tsp, to_unit: ml, conversion_factor: 4.929 },
     { from_unit: fl_oz, to_unit: ml, conversion_factor: 29.574 },

     # Weight conversions
     { from_unit: pound, to_unit: gram, conversion_factor: 453.592 },
     { from_unit: ounce, to_unit: gram, conversion_factor: 28.349 },
     { from_unit: kg, to_unit: gram, conversion_factor: 1000 },

     # Count conversions
     { from_unit: dozen, to_unit: piece, conversion_factor: 12 }
   ])

puts "Creating grocery sections..."
grocery_sections = GrocerySection.create!([
    { name: 'Produce', display_order: 1 },
    { name: 'Meat & Seafood', display_order: 2 },
    { name: 'Dairy & Eggs', display_order: 3 },
    { name: 'Pantry', display_order: 4 },
    { name: 'Frozen', display_order: 5 },
    { name: 'Beverages', display_order: 6 },
    { name: 'Snacks', display_order: 7 },
    { name: 'Bakery', display_order: 8 }
  ])

puts "Creating store sections..."
store_sections = StoreSection.create!([
    { name: 'Front of Store', display_order: 1 },
    { name: 'Produce Section', display_order: 2 },
    { name: 'Meat Counter', display_order: 3 },
    { name: 'Dairy Wall', display_order: 4 },
    { name: 'Center Aisles', display_order: 5 },
    { name: 'Frozen Section', display_order: 6 },
    { name: 'Bakery Area', display_order: 7 }
  ])

puts "Creating groceries..."
# Helper method to find sections by name
def find_grocery_section(name)
  GrocerySection.find_by(name: name)
end

def find_store_section(name)
  StoreSection.find_by(name: name)
end

groceries = Grocery.create!([
    # Produce
    { user: user, name: 'Bananas', quantity: 1, unit: dozen,
      grocery_section: find_grocery_section('Produce'),
      store_section: find_store_section('Produce Section'), emoji: 'U+1F34C' },
    { user: user, name: 'Apples', quantity: 1, unit: pound,
      grocery_section: find_grocery_section('Produce'),
      store_section: find_store_section('Produce Section'), emoji: 'U+1F34E' },

    # Meat
    { user: user, name: 'Chicken Breast', quantity: 1, unit: pound,
      grocery_section: find_grocery_section('Meat & Seafood'),
      store_section: find_store_section('Meat Counter'), emoji: 'U+1F413' },
    { user: user, name: 'Shrimp', quantity: 1, unit: pound,
      grocery_section: find_grocery_section('Meat & Seafood'),
      store_section: find_store_section('Meat Counter'), emoji: 'U+1F364' },

    # Dairy
    { user: user, name: 'Milk', quantity: 1, unit: fl_oz,
      grocery_section: find_grocery_section('Dairy & Eggs'), emoji: 'U+1F95B',
      store_section: find_store_section('Dairy Wall') },
    { user: user, name: 'Eggs', quantity: 1, unit: dozen,
      grocery_section: find_grocery_section('Dairy & Eggs'), emoji: 'U+1F95A',
      store_section: find_store_section('Dairy Wall') },

    # Pantry
    { user: user, name: 'Flour', quantity: 1, unit: pound,
      grocery_section: find_grocery_section('Pantry'),
      store_section: find_store_section('Center Aisles'), emoji: 'U+1F33E' },
    { user: user, name: 'Sugar', quantity: 1, unit: pound,
      grocery_section: find_grocery_section('Pantry'),
      store_section: find_store_section('Center Aisles'), emoji: 'U+1F370' }
  ])

puts "Creating recipes..."
banana_bread = Recipe.create!(
  user: user,
  name: 'Banana Bread',
  instructions: "1. Preheat oven to 350°F\n2. Mix dry ingredients\n3. Mash bananas and mix with wet ingredients\n4. Combine and bake for 1 hour",
  completed: false,
  notes: 'Family favorite recipe'
)

puts "Creating recipe ingredients..."
RecipeIngredient.create!([
     { recipe: banana_bread, grocery: Grocery.find_by(name: 'Bananas'), quantity: 3, unit: piece },
     { recipe: banana_bread, grocery: Grocery.find_by(name: 'Flour'), quantity: 2, unit: cup },
     { recipe: banana_bread, grocery: Grocery.find_by(name: 'Sugar'), quantity: 1, unit: cup },
     { recipe: banana_bread, grocery: Grocery.find_by(name: 'Eggs'), quantity: 2, unit: piece }
   ])

puts "Creating grocery list items..."
GroceryListItem.create!([
      { user: user, grocery: Grocery.find_by(name: 'Bananas'), quantity: 1, unit: dozen, notes: 'For banana bread', purchased: false },
      { user: user, grocery: Grocery.find_by(name: 'Milk'), quantity: 64, unit: fl_oz, notes: 'Running low', purchased: false },
      { user: user, grocery: Grocery.find_by(name: 'Chicken Breast'), quantity: 2, unit: pound, notes: 'For meal prep', purchased: true }
    ])

puts "Seed completed successfully!"
