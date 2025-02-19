FactoryBot.define do
  factory :recipe do
    association :user
    name { "Peanut Butter and Jelly Sandwich" }
    instructions { "Spread one slice of bread with the peanut butter. Spread the other slice of bread with the jelly. Press bread slices together." }
    completed { false }
    completed_at { "2025-02-17 21:35:23" }
    notes { "For kids: cut the crusts off,  For me: use chunky peanut butter" }
  end
end
