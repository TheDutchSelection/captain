require 'rails_helper'

RSpec.describe 'show app', type: :feature do
  before do
    @app = FactoryGirl.create(:app, name: 'Application 1')
    login_user
  end

  it 'should show app' do
    visit apps_path
    click_link('Application 1')
    expect(page.current_path).to eq app_path(@app)
    expect(page).to have_content 'Application 1'
  end
end
