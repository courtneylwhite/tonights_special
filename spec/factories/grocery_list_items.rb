FactoryBot.define do
  factory :grocery_list_item do
    association :user
    association :grocery
    association :unit
    association :store_section
    quantity { "9.99" }
    notes { "MyText" }
    purchased { false }
  end
end
