FactoryBot.define do
  factory :recipe_ingredient do
    quantity { "9.99" }
    association :recipe
    association :grocery
    association :unit
  end
end
