FactoryGirl.define do
  factory :app do
    sequence(:name) { |n| "Application #{n}" }
    sequence(:etcd_key) { |n| "application#{n}" }

    trait :price_comparator do
      name 'Price Comparator'
      etcd_key 'price_comparator'
    end
  end
end
