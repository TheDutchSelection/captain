RSpec.configure do |config|
  config.before(:each) do
    flush_redis
  end
end

def flush_redis
  RedisStorageService.new('local').flushall
end

module RedisStorageServiceHelper
  def self.load_redis_sample_data
    redis_storage_service = RedisStorageService.new
    redis_storage_service.hset('ht21:containers:price_comparator_nl_telecom_worker:ht21wrkprd001', 'need_restart', '0')
    redis_storage_service.hset('ht21:containers:price_comparator_nl_telecom_worker:ht21wrkprd001', 'restart', '0')
    redis_storage_service.hset('ht21:containers:price_comparator_nl_telecom_worker:ht21wrkprd001', 'update', '0')
    redis_storage_service.hset('vla1:containers:price_comparator_nl_telecom_portal:vla1wrkprd001', 'need_restart', '0')
    redis_storage_service.hset('vla1:containers:price_comparator_nl_telecom_portal:vla1wrkprd001', 'restart', '0')
    redis_storage_service.hset('vla1:containers:price_comparator_nl_telecom_portal:vla1wrkprd001', 'update', '0')
    redis_storage_service.hset('vla1:containers:price_comparator_nl_telecom_backend:vla1wrkprd002', 'need_restart', '0')
    redis_storage_service.hset('vla1:containers:price_comparator_nl_telecom_backend:vla1wrkprd002', 'restart', '0')
    redis_storage_service.hset('vla1:containers:price_comparator_nl_telecom_backend:vla1wrkprd002', 'update', '0')
    redis_storage_service.hset('vla1:containers:nginx_price_comparator_nl_telecom_portal:vla1wrkprd003', 'need_restart', '0')
    redis_storage_service.hset('vla1:containers:nginx_price_comparator_nl_telecom_portal:vla1wrkprd003', 'restart', '0')
    redis_storage_service.hset('vla1:containers:nginx_price_comparator_nl_telecom_portal:vla1wrkprd003', 'update', '0')
    redis_storage_service.hset('vla1:containers:redis_master:vla1wrkprd004', 'need_restart', '0')
    redis_storage_service.hset('vla1:containers:redis_master:vla1wrkprd004', 'restart', '0')
    redis_storage_service.hset('vla1:containers:redis_master:vla1wrkprd004', 'update', '0')
  end
end