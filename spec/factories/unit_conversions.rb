FactoryBot.define do
  factory :unit_conversion do
    from_unit { nil }
    to_unit { nil }
    conversion_factor { "9.99" }
  end
end
