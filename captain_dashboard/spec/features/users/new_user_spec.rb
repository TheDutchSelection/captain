require 'rails_helper'

RSpec.describe 'new user', type: :feature do
  before do
    login_user
  end

  it 'should create user' do
    visit users_path
    click_link 'New User'
    within('form') do
      fill_in 'user[email]', with: 'bill@microsoft.com'
      fill_in 'user[password]', with: 'itsasecrettoeverybody'
      fill_in 'user[password_confirmation]', with: 'itsasecrettoeverybody'
      select 'Member', from: 'user[role]'
    end
    click_button 'Save'
    expect(page.current_path).to eq users_path
    expect(page).to have_content 'Users'
    expect(page).to have_content 'bill@microsoft.com'
    expect(User.count).to eq 2
  end

  it 'should show error when requirements not met' do
    visit users_path
    click_link 'New User'
    click_button 'Save'
    expect(page.current_path).to eq users_path
    expect(page).to have_content 'Error'
  end

  it 'should do nothing when cancelled' do
    visit users_path
    click_link 'New User'
    within('form') do
      fill_in 'user[email]', with: 'bill@microsoft.com'
      fill_in 'user[password]', with: 'itsasecrettoeverybody'
      fill_in 'user[password_confirmation]', with: 'itsasecrettoeverybody'
      select 'Member', from: 'user[role]'
    end
    click_link 'Cancel'
    expect(page.current_path).to eq users_path
    expect(page).to have_content 'Users'
    expect(page).to_not have_content 'bill@microsoft.com'
    expect(User.count).to eq 1
  end
end
