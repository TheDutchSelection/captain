require 'rails_helper'

RSpec.describe 'show redis keys and values', type: :feature do
  before do
    RedisStorageServiceHelper.load_redis_sample_data
    login_user
  end

  it 'should show redis keys and values' do
    visit redis_path
    expect(page.current_path).to eq redis_path
    expect(page).to have_content 'vla1:containers:price_comparator_nl_telecom_portal:vla1wrkprd001'
    expect(page).to have_content 'update'
  end
end
