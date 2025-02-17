FactoryBot.define do
  factory :grocery_list_item do
    user { nil }
    grocery { nil }
    quantity { "9.99" }
    unit { nil }
    notes { "MyText" }
    purchased { false }
  end
end
