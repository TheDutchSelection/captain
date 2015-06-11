class RedisController < ApplicationController
  def index
    redis = RedisStorageService.new
    @redis_keys = redis.get_all_keys_with_fields
  end
end