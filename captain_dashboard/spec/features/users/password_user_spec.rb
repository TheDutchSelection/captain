require 'rails_helper'

RSpec.describe 'change password user', type: :feature do
  before do        
    @user = FactoryGirl.create(:user, email: 'bill@microsoft.com')    
    login_user
  end

  it 'should change password' do
    visit users_path
    click_link('bill@microsoft.com')
    click_link('Change password')
    within('form') do
      fill_in 'user[password]', with: 'trustno1'
      fill_in 'user[password_confirmation]', with: 'trustno1'
    end
    click_button 'Save'
    expect(page.current_path).to eq user_path(@user)
    expect(page).to have_content 'User'
    expect(page).to have_content 'bill@microsoft.com'
    expect(@user.reload.valid_password?('trustno1')).to be_truthy
  end

  it 'should show error when requirements not met' do
    visit users_path
    click_link('bill@microsoft.com')
    click_link('Change password')
    within('form') do
      fill_in 'user[password]', with: 'trustno1'
    end
    click_button 'Save'
    expect(page.current_path).to eq password_user_path(@user)
    expect(page).to have_content 'Change password'
    expect(page).to have_content 'Error'
    expect(@user.reload.valid_password?('trustno1')).to be_falsy
  end

  it 'should do nothing when cancelled' do
    visit users_path
    click_link('bill@microsoft.com')
    click_link('Change password')
    within('form') do
      fill_in 'user[password]', with: 'trustno1'
      fill_in 'user[password_confirmation]', with: 'trustno1'
    end
    click_link 'Cancel'
    expect(page.current_path).to eq user_path(@user)
    expect(page).to have_content 'User'
    expect(page).to have_content 'bill@microsoft.com'
    expect(@user.reload.valid_password?('trustno1')).to be_falsy
  end
  
end
