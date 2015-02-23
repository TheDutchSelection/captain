class App < ActiveRecord::Base

  has_and_belongs_to_many :zones

  validates :name, :etcd_key, presence: true, uniqueness: true
end
