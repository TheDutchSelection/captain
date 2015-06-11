class RedisStorageService

  attr_reader :namespace

  NAMESPACE_EXTENTION = ':captain:'
  REDIS_FALSE_VALUE = 0
  REDIS_NEED_RESTART_KEY = 'need_restart'
  REDIS_TRUE_VALUE = 1
  REDIS_UPDATE_KEY = 'update'

  def initialize(namespace = '', config = REDIS_STORAGE_SERVICE_DEFAULT_CONFIG[:config])
    @namespace = (REDIS_STORAGE_SERVICE_DEFAULT_CONFIG[:namespace] + NAMESPACE_EXTENTION + namespace).chomp(':')
    @redis = Redis::Namespace.new(@namespace, redis: Redis.new(config))
  end

  def set_app_key_in_zone(zone_key, app_key, field, value)
    result = false
    zone_container_keys = @redis.keys(zone_key + ':containers*')
    zone_container_keys.each do |zone_container_key|
      if zone_container_key.include?(':' + app_key)
        @redis.hset(zone_container_key, field, value)
        result = true
      end
    end

    result
  end

  def get_servers_from_zone(zone_key, app_key = nil)
    result = []
    zone_container_keys = @redis.keys(zone_key + ':containers*')
    zone_container_keys.each do |zone_container_key|
      if app_key.present?
        if zone_container_key.include?(':' + app_key)
          host_name = zone_container_key.split(':')[-1]
          result.push(host_name)
        end
      else
        host_name = zone_container_key.split(':')[-1]
        result.push(host_name)
      end
    end

    result.uniq
  end

  def get_all_keys_with_fields
    keys = @redis.keys('*')

    result = {}
    keys.each do |key|
      result[key] = @redis.hgetall(key)
    end

    result
  end

  def method_missing(meth, *args, &block)
    if @redis.respond_to?(meth)
      @redis.send(meth, *args, &block)
    end
  end

end
