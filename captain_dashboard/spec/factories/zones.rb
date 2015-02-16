FactoryGirl.define do
  factory :zone do
    sequence(:name) { |n| "Vultr - Amsterdam #{n}" }
    sequence(:etcd_key) { |n| "vla#{n}" }
  end
end
