require 'rails_helper'

RSpec.describe RedisStorageService do

  let(:redis_storage_service) { RedisStorageService.new }

  describe '#set' do
    it 'should return true' do
      expect(redis_storage_service.set('key', 'value')).to be_truthy
    end

    it 'should place the key under the defined namespace' do
      expect(redis_storage_service.namespace).to eq 'tds:captain'
    end
  end

  describe '#get' do
    it 'should return value' do
      redis_storage_service.set('key', 'value')
      expect(redis_storage_service.get('key')).to eq 'value'
    end
  end
 
  describe '#sadd' do
    it 'should return true' do
      expect(redis_storage_service.sadd('key', 'foobar')).to be_truthy
    end
  end

  describe '#smembers' do
    it 'should return array' do
      redis_storage_service.sadd('key', 'value')
      expect(redis_storage_service.smembers('key')).to eq ['value']
    end    
  end
  
  describe '#flushdb' do
    it 'should return true' do
      expect(redis_storage_service.flushdb).to be_truthy
    end
  end

  describe '#get_servers_from_zone' do
    before do
      RedisStorageServiceHelper.load_redis_sample_data
    end

    let(:zone) {FactoryGirl.create(:zone, :vla1)}
    let(:app) {FactoryGirl.create(:app, :price_comparator, zones: [zone])}

    it 'should get all servers when no app specified' do
      servers = redis_storage_service.get_servers_from_zone(zone.redis_key)
      expect(servers).to be_a(Array)
      expect(servers).to include('vla1wrkprd001')
      expect(servers).to include('vla1wrkprd002')
      expect(servers).to include('vla1wrkprd003')
      expect(servers).to_not include('ht21wrkprd001')
      expect(servers).to_not include('doa3wrkprd001')
    end

    it 'should get only the servers for a specific app when an app is specified' do
      servers = redis_storage_service.get_servers_from_zone(zone.redis_key, app.redis_key)
      expect(servers).to be_a(Array)
      expect(servers).to include('vla1wrkprd001')
      expect(servers).to include('vla1wrkprd002')
      expect(servers).to_not include('ht21wrkprd001')
      expect(servers).to_not include('vla1wrkprd003')
    end
  end
  
  describe '#set_app_key_in_zone' do
    before do
      RedisStorageServiceHelper.load_redis_sample_data
    end

    let(:zone) {FactoryGirl.create(:zone, :vla1)}
    let(:app) {FactoryGirl.create(:app, :price_comparator, zones: [zone])}

    it 'should set the specified key to the specified value' do
      field = RedisStorageService::REDIS_NEED_RESTART_KEY
      value = RedisStorageService::REDIS_TRUE_VALUE
      redis_storage_service.set_app_key_in_zone(zone.redis_key, app.redis_key, field, value)

      need_restart_value_1 = redis_storage_service.hget('vla1:containers:price_comparator_nl_telecom_portal:vla1wrkprd001', 'need_restart')
      need_restart_value_2 = redis_storage_service.hget('vla1:containers:price_comparator_nl_telecom_backend:vla1wrkprd002', 'need_restart')
      need_restart_value_3 = redis_storage_service.hget('vla1:containers:nginx_price_comparator_nl_telecom_portal:vla1wrkprd003', 'need_restart')
      need_restart_value_4 = redis_storage_service.hget('vla1:containers:redis_master:vla1wrkprd004', 'need_restart')
      need_restart_value_5 = redis_storage_service.hget('ht21:containers:price_comparator_nl_telecom_worker:ht21wrkprd001', 'need_restart')
      expect(need_restart_value_1).to eq '1'
      expect(need_restart_value_2).to eq '1'
      expect(need_restart_value_3).to eq '0'
      expect(need_restart_value_4).to eq '0'
      expect(need_restart_value_5).to eq '0'
    end

    it 'should return false for non existant app' do
      key = RedisStorageService::REDIS_NEED_RESTART_KEY
      value = RedisStorageService::REDIS_TRUE_VALUE

      expect(redis_storage_service.set_app_key_in_zone(zone.redis_key, 'madness', key, value)).to be_falsy
    end
  end

  describe '#get_all_keys_with_fields' do
    before do
      RedisStorageServiceHelper.load_redis_sample_data
    end

    it 'should return a hash with keys, fields and values in the namespace' do
      all_keys_and_values = redis_storage_service.get_all_keys_with_fields

      expect(all_keys_and_values).to be_a(Hash)
      expect(all_keys_and_values['vla1:containers:price_comparator_nl_telecom_portal:vla1wrkprd001']).to be_a(Hash)
      expect(all_keys_and_values['vla1:containers:price_comparator_nl_telecom_portal:vla1wrkprd001']['need_restart']).to eq '0'
    end

    it 'should return an empty hash when redis namespace is empty' do
      redis_storage_service.flushall
      all_keys_and_values = redis_storage_service.get_all_keys_with_fields

      expect(all_keys_and_values).to be_a(Hash)
      expect(all_keys_and_values).to be_empty
    end
  end

end

