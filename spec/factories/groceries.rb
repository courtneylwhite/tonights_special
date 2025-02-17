FactoryBot.define do
  factory :grocery do
    user { nil }
    store_section { nil }
    name { "MyString" }
    quantity { "9.99" }
    unit { nil }
  end
end
