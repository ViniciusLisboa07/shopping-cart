FactoryBot.define do
  factory :product do
    name { "Sample Product" }
    price { 99.99 }

    trait :expensive do
      price { 999.99 }
    end

    trait :cheap do
      price { 9.99 }
    end

    trait :free do
      price { 0.0 }
    end
  end
end
