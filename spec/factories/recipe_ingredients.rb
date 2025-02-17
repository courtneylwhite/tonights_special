FactoryBot.define do
  factory :recipe_ingredient do
    recipe { nil }
    grocery { nil }
    quantity { "9.99" }
    unit { nil }
  end
end
