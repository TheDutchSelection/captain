FactoryGirl.define do
  factory :zone do
    sequence(:name) { |n| "Vultr - Amsterdam #{n}" }
    sequence(:etcd_key) { |n| "vla#{n}" }

    trait :ht21 do
      name 'Hetzner - 21'
      etcd_key 'ht21'
    end

    trait :doa3 do
      name 'DigitalOcean - Amsterdam 3'
      etcd_key 'doa3'
    end

    trait :vla1 do
      name 'Vultr - Amsterdam 1'
      etcd_key 'vla1'
    end
  end
end
