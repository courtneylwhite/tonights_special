# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Create User
User.create!(
  email: 'example@email.com',
  password: 'password123',
  password_confirmation: 'password123'
)

groceries = {
  'Baking': [
    { id: 1, name: 'Flour', emoji: '🌾', quantity: 5, unit: 'lbs' },
    { id: 2, name: 'Sugar', emoji: '🧂', quantity: 4, unit: 'lbs' },
    { id: 3, name: 'Baking Powder', emoji: '🧪', quantity: 8, unit: 'oz' },
    { id: 4, name: 'Vanilla Extract', emoji: '🍶', quantity: 4, unit: 'oz' },
    { id: 5, name: 'Chocolate Chips', emoji: '🍫', quantity: 12, unit: 'oz' },
    { id: 23, name: 'Brown Sugar', emoji: '🍯', quantity: 2, unit: 'lbs' },
    { id: 24, name: 'Baking Soda', emoji: '🧪', quantity: 12, unit: 'oz' }
  ],
  'Canned Goods': [
    { id: 6, name: 'Tomatoes', emoji: '🍅', quantity: 4, unit: 'cans' },
    { id: 7, name: 'Beans', emoji: '🫘', quantity: 6, unit: 'cans' },
    { id: 8, name: 'Corn', emoji: '🌽', quantity: 3, unit: 'cans' },
    { id: 9, name: 'Tuna', emoji: '🐟', quantity: 5, unit: 'cans' },
    { id: 10, name: 'Soup', emoji: '🥣', quantity: 4, unit: 'cans' },
    { id: 25, name: 'Green Beans', emoji: '🥬', quantity: 3, unit: 'cans' },
    { id: 26, name: 'Chickpeas', emoji: '🫘', quantity: 2, unit: 'cans' }
  ],
  'Breakfast': [
    { id: 11, name: 'Cereal', emoji: '🥣', quantity: 2, unit: 'boxes' },
    { id: 12, name: 'Oatmeal', emoji: '🥄', quantity: 42, unit: 'oz' },
    { id: 13, name: 'Pancake Mix', emoji: '🥞', quantity: 32, unit: 'oz' },
    { id: 14, name: 'Maple Syrup', emoji: '🍯', quantity: 16, unit: 'oz' },
    { id: 27, name: 'Granola', emoji: '🥜', quantity: 24, unit: 'oz' },
    { id: 28, name: 'Coffee', emoji: '☕', quantity: 2, unit: 'lbs' }
  ],
  'Snacks': [
    { id: 15, name: 'Crackers', emoji: '🍘', quantity: 3, unit: 'boxes' },
    { id: 16, name: 'Nuts', emoji: '🥜', quantity: 16, unit: 'oz' },
    { id: 17, name: 'Dried Fruit', emoji: '🍇', quantity: 12, unit: 'oz' },
    { id: 18, name: 'Popcorn', emoji: '🍿', quantity: 3, unit: 'bags' },
    { id: 29, name: 'Chips', emoji: '🥔', quantity: 2, unit: 'bags' },
    { id: 30, name: 'Pretzels', emoji: '🥨', quantity: 1, unit: 'bag' }
  ],
  'Pasta & Grains': [
    { id: 19, name: 'Spaghetti', emoji: '🍝', quantity: 3, unit: 'lbs' },
    { id: 20, name: 'Rice', emoji: '🍚', quantity: 5, unit: 'lbs' },
    { id: 21, name: 'Quinoa', emoji: '🌾', quantity: 24, unit: 'oz' },
    { id: 22, name: 'Couscous', emoji: '🥘', quantity: 16, unit: 'oz' },
    { id: 31, name: 'Penne', emoji: '🍝', quantity: 2, unit: 'lbs' },
    { id: 32, name: 'Brown Rice', emoji: '🍚', quantity: 3, unit: 'lbs' }
  ]
}

# Create Groceries
