FactoryBot.define do
  factory :recipe do
    user { nil }
    name { "MyString" }
    instructions { "MyText" }
    completed { false }
    completed_at { "2025-02-17 21:35:23" }
    notes { "MyText" }
  end
end
