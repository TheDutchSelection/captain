require 'rails_helper'

RSpec.describe EtcdStorageService do
  before do
    EtcdStorageServiceHelper.load_etcd_sample_data
  end

  let(:etcd_storage_service) { EtcdStorageService.new }

  describe '#get' do
    before(:all) do
      etcd_storage_service = EtcdStorageService.new
      etcd_storage_service.set('path/to/key', 'value')
    end

    it 'should return a hash for a tree' do
      expect(etcd_storage_service.get('path/')).to be_a(Hash)
    end

    it 'should return value for a specific key' do
      expect(etcd_storage_service.get('path/to/key')).to eql 'value'
    end

    it 'should return an empty hash for non existing key' do
      expect(etcd_storage_service.get('bla/')).to be_a(Hash)
    end
  end

  describe '#set' do
    it 'should return true' do
      result = etcd_storage_service.set('path/to/another/key', 'value')

      expect(result).to be_a(Hash)
      expect(result['node']['value']).to eq 'value'
    end
  end

  describe '#delete' do
    before(:all) do
      etcd_storage_service = EtcdStorageService.new
      etcd_storage_service.set('path/to/key', 'value')
    end

    it 'should delete a value' do
      etcd_storage_service.delete('path/to/key')
      expect(etcd_storage_service.get('path/to/key')).to be_empty
    end
  end

  describe '#get_servers_from_zone' do
    let(:zone) {FactoryGirl.create(:zone, :vla1)}
    let(:app) {FactoryGirl.create(:app, :price_comparator, zones: [zone])}

    it 'should get all servers when no app specified' do
      servers = etcd_storage_service.get_servers_from_zone(zone.etcd_key)
      expect(servers).to be_a(Array)
      expect(servers).to include('vla1wrkprd001')
      expect(servers).to include('vla1wrkprd002')
      expect(servers).to include('vla1wrkprd003')
      expect(servers).to_not include('doa3wrkprd001')
    end

    it 'should get only the servers for a specific app when an app is specified' do
      servers = etcd_storage_service.get_servers_from_zone(zone.etcd_key, app.etcd_key)
      expect(servers).to be_a(Array)
      expect(servers).to include('vla1wrkprd001')
      expect(servers).to include('vla1wrkprd002')
      expect(servers).to_not include('vla1wrkprd003')
    end
  end

  describe '#set_app_key_in_zone' do
    let(:zone) {FactoryGirl.create(:zone, :vla1)}
    let(:app) {FactoryGirl.create(:app, :price_comparator, zones: [zone])}

    it 'should set the specified key to the specified value' do
      key = EtcdStorageService::ETCD_NEED_RESTART_KEY
      value = EtcdStorageService::ETCD_TRUE_VALUE
      etcd_storage_service.set_app_key_in_zone(zone.etcd_key, app.etcd_key, key, value)

      need_restart_value_1 = etcd_storage_service.get('vla1/containers/price_comparator_nl_telecom_portal/vla1wrkprd001/need_restart')
      need_restart_value_2 = etcd_storage_service.get('vla1/containers/price_comparator_nl_telecom_backend/vla1wrkprd002/need_restart')
      need_restart_value_3 = etcd_storage_service.get('vla1/containers/redis_master/vla1wrkprd003/need_restart')
      expect(need_restart_value_1).to eq '1'
      expect(need_restart_value_2).to eq '1'
      expect(need_restart_value_3).to eq '0'
    end

    it 'should return false for non existant app' do
      key = EtcdStorageService::ETCD_NEED_RESTART_KEY
      value = EtcdStorageService::ETCD_TRUE_VALUE

      expect(etcd_storage_service.set_app_key_in_zone(zone.etcd_key, 'madness', key, value)).to be_falsy
    end
  end
end
