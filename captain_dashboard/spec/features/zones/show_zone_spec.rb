require 'rails_helper'

RSpec.describe 'show zone', type: :feature do
  before do
    @zone = FactoryGirl.create(:zone, :vla1)
    login_user
  end

  it 'should show zone' do
    visit zones_path
    click_link('Vultr - Amsterdam 1')
    expect(page.current_path).to eq zone_path(@zone)
    expect(page).to have_content 'Vultr - Amsterdam 1'
  end
end
