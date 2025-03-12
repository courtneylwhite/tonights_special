FactoryBot.define do
  factory :grocery do
    association :user
    association :grocery_section
    association :unit
    sequence(:name) { |n| "grocery item #{n}" }
    quantity { 1.0 }
    emoji { "U+1F34E" }
  end
end
