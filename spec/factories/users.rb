FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    # Add any other required fields for your User model here
    # For example:
    # first_name { "John" }
    # last_name { "Doe" }
    # confirmed_at { Time.current } # if using confirmable
  end
end
