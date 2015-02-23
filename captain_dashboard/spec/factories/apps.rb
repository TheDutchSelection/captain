FactoryGirl.define do
  factory :app do
    sequence(:name) { |n| "Application #{n}" }
    sequence(:etcd_key) { |n| "application#{n}" }
  end
end
