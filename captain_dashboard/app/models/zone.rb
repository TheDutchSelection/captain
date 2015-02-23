class Zone < ActiveRecord::Base

  has_and_belongs_to_many :apps

  validates :name, :etcd_key, presence: true, uniqueness: true

  def servers(app = nil)
    etcd_storage_service = EtcdStorageService.new
    app_etcd_key =
      if app.present?
        app.etcd_key
      else
        nil
      end

    etcd_storage_service.get_servers_from_zone(etcd_key, app_etcd_key)
  end
end
