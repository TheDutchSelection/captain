class Zone < ActiveRecord::Base

  has_and_belongs_to_many :apps

  validates :name, :redis_key, presence: true, uniqueness: true

  def servers(app = nil)
    redis_storage_service = RedisStorageService.new()
    app_redis_key =
      if app.present?
        app.redis_key
      else
        nil
      end

    redis_storage_service.get_servers_from_zone(redis_key, app_redis_key)
  end
end
