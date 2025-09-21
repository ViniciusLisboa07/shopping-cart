FactoryBot.define do
  factory :cart_item do
    association :cart
    association :product
    quantity { 1 }

    trait :multiple_quantity do
      quantity { 3 }
    end

    trait :large_quantity do
      quantity { 10 }
    end

    # Para criar cart_item com produto específico
    trait :with_expensive_product do
      association :product, :expensive
    end

    trait :with_cheap_product do
      association :product, :cheap
    end
  end
end
