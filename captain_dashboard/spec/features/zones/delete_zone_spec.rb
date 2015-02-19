require 'rails_helper'

RSpec.describe 'delete zone', type: :feature do
  before do
    @zone = FactoryGirl.create(:zone, name: 'Vultr - Amsterdam 1')
    login_user
  end

  it 'should delete zone' do
    visit zones_path
    click_link('Vultr - Amsterdam 1')
    click_link('Delete')
    # Implicit confirm
    expect(page.current_path).to eq zones_path
    expect(page).to have_content 'There are no zones yet.'
    expect(page).to_not have_content 'Vultr - Amsterdam 1'
  end
end
