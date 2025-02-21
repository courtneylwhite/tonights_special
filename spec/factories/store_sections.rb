FactoryBot.define do
  factory :store_section do
    sequence(:name) { |n| "Grocery Aisle #{n}" }
    display_order { 1 }
  end
end
