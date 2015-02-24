class App < ActiveRecord::Base

  has_and_belongs_to_many :zones

  validates :name, :etcd_key, presence: true, uniqueness: true

  def set_key_in_zone(zone, key, value)
    etcd_storage_service = EtcdStorageService.new

    etcd_storage_service.set_app_key_in_zone(zone.etcd_key, etcd_key, key, value)
  end
end
