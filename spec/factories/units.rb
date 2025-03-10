FactoryBot.define do
  factory :unit do
    sequence(:name) { |n| "Unit#{n}" }
    sequence(:abbreviation) { |n| "u#{n}" }
    category { "volume" }
  end
end
