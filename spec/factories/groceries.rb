FactoryBot.define do
  factory :grocery do
    association :user
    association :store_section
    association :grocery_section
    association :unit
    name { "Test Grocery" }
    quantity { 1.0 }
    emoji { "U+1F34E" } # apple emoji
  end
end
