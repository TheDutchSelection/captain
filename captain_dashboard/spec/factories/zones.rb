FactoryGirl.define do
  factory :zone do
    sequence(:name) { |n| "Vultr - Amsterdam #{n}" }
    sequence(:redis_key) { |n| "vla#{n}" }

    trait :ht21 do
      name 'Hetzner - 21'
      redis_key 'ht21'
    end

    trait :doa3 do
      name 'DigitalOcean - Amsterdam 3'
      redis_key 'doa3'
    end

    trait :vla1 do
      name 'Vultr - Amsterdam 1'
      redis_key 'vla1'
    end
  end
end
