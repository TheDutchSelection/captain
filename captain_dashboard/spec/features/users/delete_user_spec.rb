require 'rails_helper'

RSpec.describe 'delete user', type: :feature do
  before do
    @user = FactoryGirl.create(:user, email: 'bill@microsoft.com')
    login_user
  end

  it 'should delete user' do
    visit users_path
    click_link('bill@microsoft.com')
    click_link('Delete')
    # Implicit confirm
    expect(page.current_path).to eq users_path
    expect(page).to_not have_content 'bill@microsoft.com'
  end
end
