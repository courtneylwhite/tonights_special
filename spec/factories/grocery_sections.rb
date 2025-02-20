FactoryBot.define do
  factory :grocery_section do
    association :user
    name { "bread" }
    display_order { 1 }
  end
end
