require 'rails_helper'

RSpec.describe 'delete app', type: :feature do
  before do
    @app = FactoryGirl.create(:app, name: 'Application 1')
    login_user
  end

  it 'should delete app' do
    visit apps_path
    click_link('Application 1')
    click_link('Delete')
    # Implicit confirm
    expect(page.current_path).to eq apps_path
    expect(page).to have_content 'There are no apps yet.'
    expect(page).to_not have_content 'Application 1'
  end
end
