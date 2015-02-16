class Zone < ActiveRecord::Base

  validates :name, :etcd_key, presence: true, uniqueness: true
end
