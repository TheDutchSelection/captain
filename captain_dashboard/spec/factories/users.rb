FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "katz#{n}@ruby-lang.org" }
    password 'iloveruby'
    role 'admin'
  end
end
