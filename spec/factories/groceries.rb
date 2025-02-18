FactoryBot.define do
  factory :grocery do
    user { nil }
    store_section { nil }
    name { "bread" }
    quantity { "9.99" }
    unit { nil }
  end
end
