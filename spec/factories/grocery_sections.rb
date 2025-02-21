FactoryBot.define do
  factory :grocery_section do
    association :user
    name { "bread" }
    sequence(:display_order) { |n| n }
  end
end
