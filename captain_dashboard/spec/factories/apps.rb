FactoryGirl.define do
  factory :app do
    sequence(:name) { |n| "Application #{n}" }
    sequence(:redis_key) { |n| "application#{n}" }

    trait :price_comparator do
      name 'Price Comparator'
      redis_key 'price_comparator'
    end
  end
end
