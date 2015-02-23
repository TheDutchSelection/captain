require 'rails_helper'

RSpec.describe EtcdStorageService do

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
      expect(etcd_storage_service.set('path/to/another/key', 'value')).to be_truthy
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
    before do
      load_etcd_sample_data
    end

    let(:zone) {FactoryGirl.create(:zone, :vla1)}

    it 'should get all servers when no app specified' do
      servers = etcd_storage_service.get_servers_from_zone(zone)
      expect(servers).to be_a(Array)
      expect(servers).to include('vla1wrkprd001')
      expect(servers).to include('vla1wrkprd002')
      expect(servers).to_not include('doa3wrkprd001')
    end
  end
end
