FactoryBot.define do
  factory :recipe_category do
    association :user
    name { "Dinner" }
    sequence(:display_order) { |n| n }
  end
end
