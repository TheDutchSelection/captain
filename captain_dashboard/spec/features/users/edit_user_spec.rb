require 'rails_helper'

RSpec.describe 'edit user', type: :feature do
  before do
    @user = FactoryGirl.create(:user, email: 'bill@microsoft.com')
    login_user
  end

  it 'should save user' do
    visit users_path
    click_link('bill@microsoft.com')
    click_link('Edit')
    within('form') do
      fill_in 'user[email]', with: 'steve@microsoft.com'
      select 'Admin', from: 'user[role]'
    end
    click_button('Save')
    expect(page.current_path).to eq user_path(@user)
    expect(page).to have_content 'User'
    expect(page).to have_content 'steve@microsoft.com'
    expect(page).to_not have_content 'bill@microsoft.com'
  end

  it 'should show error when requirements not met' do
    visit users_path
    click_link('bill@microsoft.com')
    click_link('Edit')
    within('form') do
      fill_in 'user[email]', with: ''
      select 'Admin', from: 'user[role]'
    end
    click_button('Save')
    expect(page.current_path).to eq user_path(@user)
    expect(page).to have_content 'Edit User'
    expect(page).to have_content 'Error'
  end

  it 'should do nothing when cancelled' do
    visit users_path
    click_link('bill@microsoft.com')
    click_link('Edit')
    within('form') do
      fill_in 'user[email]', with: 'steve@microsoft.com'
      select 'Admin', from: 'user[role]'
    end
    click_link('Cancel')
    expect(page.current_path).to eq user_path(@user)
    expect(page).to have_content 'User'
    expect(page).to have_content 'bill@microsoft.com'
    expect(page).to_not have_content 'steve@microsoft.com'
  end
end
