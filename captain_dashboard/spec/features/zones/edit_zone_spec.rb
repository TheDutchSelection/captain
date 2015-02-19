require 'rails_helper'

RSpec.describe 'edit zone', type: :feature do
  before do
    @zone = FactoryGirl.create(:zone, name: 'Vultr - Amsterdam 1')
    login_user
  end

  it 'should save zone' do
    visit zones_path
    click_link('Vultr - Amsterdam 1')
    click_link('Edit')
    within('form') do
      fill_in 'zone[name]', with: 'Vultr - Amsterdam 2'
      fill_in 'zone[etcd_key]', with: 'vla1'
    end
    click_button 'Save'
    expect(page.current_path).to eq zone_path(@zone)
    expect(page).to have_content 'Zones'
    expect(page).to have_content 'Vultr - Amsterdam 2'
    expect(page).to_not have_content 'Vultr - Amsterdam 1'
  end

  it 'should show error when requirements not met' do
    visit zones_path
    click_link('Vultr - Amsterdam 1')
    click_link('Edit')
    within('form') do
      fill_in 'zone[name]', with: ''
    end
    click_button 'Save'
    expect(page.current_path).to eq zone_path(@zone)
    expect(page).to have_content 'Error'
  end

  it 'should do nothing when cancelled' do
    visit zones_path
    click_link('Vultr - Amsterdam 1')
    click_link('Edit')
    within('form') do
      fill_in 'zone[name]', with: 'Vultr - Amsterdam 2'
      fill_in 'zone[etcd_key]', with: 'vla1'
    end
    click_link 'Cancel'
    expect(page.current_path).to eq zone_path(@zone)
    expect(page).to have_content 'Zones'
    expect(page).to have_content 'Vultr - Amsterdam 1'
    expect(page).to_not have_content 'Vultr - Amsterdam 2'
  end
end
