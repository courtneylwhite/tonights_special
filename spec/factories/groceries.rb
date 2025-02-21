FactoryBot.define do
  factory :grocery do
    association :user
    association :store_section
    association :grocery_section
    association :unit
    sequence(:name) { |n| "Grocery Item #{n}" }
    quantity { 1.0 }
    emoji { "U+1F34E" }
  end
end
