require 'rails_helper'

RSpec.describe 'show user', type: :feature do
  before do    
    @user = login_user
    @new_user = FactoryGirl.create(:user, email: 'bill@microsoft.com')    
  end

  context 'when admin' do
    before do
      @user.update_attribute(:role, 'admin')
    end

    it 'should show user' do
      visit users_path
      click_link('bill@microsoft.com')
      expect(page.current_path).to eq user_path(@new_user)
      expect(page).to have_content 'bill@microsoft.com'
    end
  end
  
  context 'when not admin' do
    before :each do
      @user.update_attribute(:role, 'member')
    end

    it 'should not show user' do
      visit users_path
      expect(page.current_path).to eq zones_path
      expect(page).to_not have_content 'Last sign in at'
    end
  end  
  
end
