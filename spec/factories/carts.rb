FactoryBot.define do
  factory :cart do
    total_price { 0.0 }
    last_interaction_at { Time.current }
    abandoned_at { nil }

    trait :with_products do
      after(:create) do |cart|
        create_list(:cart_item, 2, cart: cart)
        cart.reload
      end
    end

    trait :abandoned do
      abandoned_at { 1.day.ago }
      last_interaction_at { 4.hours.ago }
    end

    trait :old_abandoned do
      abandoned_at { 8.days.ago }
      last_interaction_at { 8.days.ago }
    end

    trait :inactive do
      last_interaction_at { 4.hours.ago }
    end

    # Alias para compatibilidade com testes existentes
    factory :shopping_cart
  end
end
