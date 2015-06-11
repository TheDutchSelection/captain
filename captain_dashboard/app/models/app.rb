class App < ActiveRecord::Base

  has_and_belongs_to_many :zones

  validates :name, :redis_key, presence: true, uniqueness: true

  def set_key_in_zone(zone, key, value)
    redis_storage_service = RedisStorageService.new

    redis_storage_service.set_app_key_in_zone(zone.redis_key, redis_key, key, value)
  end
end
