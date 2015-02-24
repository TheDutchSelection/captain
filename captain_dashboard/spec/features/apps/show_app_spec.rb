require 'rails_helper'

RSpec.describe 'show app', type: :feature do
  before do
    zone = FactoryGirl.create(:zone, :vla1)
    @app = FactoryGirl.create(:app, :price_comparator, zones: [zone])
    EtcdStorageServiceHelper.load_etcd_sample_data
    login_user
  end

  it 'should show app' do
    visit apps_path
    click_link('Price Comparator')
    expect(page.current_path).to eq app_path(@app)
    expect(page).to have_content 'Price Comparator'
    expect(page).to have_content 'vla1wrkprd001, vla1wrkprd002'
  end

  describe 'clicking the zone buttons' do
    let(:etcd_storage_service) { EtcdStorageService.new }
    
    it 'should set the update key in etcd to 1 when clicked' do
      visit apps_path
      click_link('Price Comparator')
      click_link('Update')

      update_value_1 = etcd_storage_service.get('vla1/containers/price_comparator_nl_telecom_portal/vla1wrkprd001/update')
      update_value_2 = etcd_storage_service.get('vla1/containers/price_comparator_nl_telecom_backend/vla1wrkprd002/update')
      update_value_3 = etcd_storage_service.get('vla1/containers/nginx_price_comparator_nl_telecom_portal/vla1wrkprd003/update')
      update_value_4 = etcd_storage_service.get('vla1/containers/redis_master/vla1wrkprd004/update')
      expect(update_value_1).to eq '1'
      expect(update_value_2).to eq '1'
      expect(update_value_3).to eq '0'
      expect(update_value_4).to eq '0'
    end

    it 'should set the restart key in etcd to 1 when clicked' do
      visit apps_path
      click_link('Price Comparator')
      click_link('Restart')

      need_restart_value_1 = etcd_storage_service.get('vla1/containers/price_comparator_nl_telecom_portal/vla1wrkprd001/need_restart')
      need_restart_value_2 = etcd_storage_service.get('vla1/containers/price_comparator_nl_telecom_backend/vla1wrkprd002/need_restart')
      need_restart_value_3 = etcd_storage_service.get('vla1/containers/nginx_price_comparator_nl_telecom_portal/vla1wrkprd003/need_restart')
      need_restart_value_4 = etcd_storage_service.get('vla1/containers/redis_master/vla1wrkprd004/need_restart')
      expect(need_restart_value_1).to eq '1'
      expect(need_restart_value_2).to eq '1'
      expect(need_restart_value_3).to eq '0'
      expect(need_restart_value_4).to eq '0'
    end
  end
end
