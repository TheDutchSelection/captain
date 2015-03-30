require 'rails_helper'

RSpec.describe 'new app', type: :feature do
  before do
    login_user
    FactoryGirl.create(:zone, name: 'Vultr - Amsterdam 1')
  end

  it 'should create a app' do
    visit apps_path
    click_link 'New App'
    within('form') do
      fill_in 'app[name]', with: 'Application 1'
      fill_in 'app[etcd_key]', with: 'vla1'
      select 'Vultr - Amsterdam 1', :from => 'app[zone_ids][]'
    end
    click_button 'Save'
    expect(page.current_path).to eq apps_path
    expect(page).to have_content 'Apps'
    expect(page).to have_content 'Application 1'
  end

  it 'should show error when requirements not met' do
    visit apps_path
    click_link 'New App'
    within('form') do
      fill_in 'app[name]', with: ''
      fill_in 'app[etcd_key]', with: ''
    end
    click_button 'Save'
    expect(page.current_path).to eq apps_path
    expect(page).to have_content 'Error'
  end

  it 'should do nothing when cancelled' do
    visit apps_path
    click_link 'New App'
    within('form') do
      fill_in 'app[name]', with: 'Application 1'
      fill_in 'app[etcd_key]', with: 'vla1'
    end
    click_link 'Cancel'
    expect(page.current_path).to eq apps_path
    expect(page).to_not have_content 'Application 1'
  end
end
