FactoryBot.define do
  factory :store_section do
    association :user
    sequence(:name) { |n| "Grocery Aisle #{n}" }
    sequence(:display_order) { |n| n }
  end
end
