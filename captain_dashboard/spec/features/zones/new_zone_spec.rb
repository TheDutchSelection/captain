require 'rails_helper'

RSpec.describe 'new zone', type: :feature do
  before do
    login_user
  end

  it 'should create a zone' do
    visit zones_path
    click_link 'New Zone'
    within('form') do
      fill_in 'zone[name]', with: 'Vultr - Amsterdam 1'
      fill_in 'zone[redis_key]', with: 'vla1'
    end
    click_button 'Save'
    expect(page.current_path).to eq zones_path
    expect(page).to have_content 'Zones'
    expect(page).to have_content 'Vultr - Amsterdam 1'
  end

  it 'should show error when requirements not met' do
    visit zones_path
    click_link 'New Zone'
    within('form') do
      fill_in 'zone[name]', with: ''
      fill_in 'zone[redis_key]', with: ''
    end
    click_button 'Save'
    expect(page.current_path).to eq zones_path
    expect(page).to have_content 'Error'
  end

  it 'should do nothing when cancelled' do
    visit zones_path
    click_link 'New Zone'
    within('form') do
      fill_in 'zone[name]', with: 'Vultr - Amsterdam 1'
      fill_in 'zone[redis_key]', with: 'vla1'
    end
    click_link 'Cancel'
    expect(page.current_path).to eq zones_path
    expect(page).to_not have_content 'Vultr - Amsterdam 1'
  end
end
