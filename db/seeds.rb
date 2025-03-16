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
Unit.create!(name: 'Cup', abbreviation: 'C.', category: 'volume')
Unit.create!(name: 'Tablespoon', abbreviation: 'Tbsp.', category: 'volume')
Unit.create!(name: 'Teaspoon', abbreviation: 'tsp.', category: 'volume')
Unit.create!(name: 'Fluid Ounce', abbreviation: 'fl. oz.', category: 'volume')
Unit.create!(name: 'Milliliter', abbreviation: 'ml.', category: 'volume')

# Weight units
Unit.create!(name: 'Pound', abbreviation: 'lb.', category: 'weight')
Unit.create!(name: 'Ounce', abbreviation: 'oz.', category: 'weight')
Unit.create!(name: 'Gram', abbreviation: 'g.', category: 'weight')
Unit.create!(name: 'Kilogram', abbreviation: 'kg.', category: 'weight')

# Count units
Unit.create!(name: 'Piece', abbreviation: 'piece', category: 'count')
Unit.create!(name: 'Dozen', abbreviation: 'dozen', category: 'count')
Unit.create!(name: 'Whole', abbreviation: 'whole', category: 'count')
Unit.create!(name: 'Slice', abbreviation: 'slice', category: 'count')

# Other units
Unit.create!(name: "To Taste", abbreviation: 'to taste', category: 'other')


puts "Seed completed successfully!"
