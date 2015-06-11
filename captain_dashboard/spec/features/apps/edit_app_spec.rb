require 'rails_helper'

RSpec.describe 'edit app', type: :feature do
  before do
    @app = FactoryGirl.create(:app, name: 'Application 1')
    login_user
  end

  it 'should save app' do
    visit apps_path
    click_link('Application 1')
    click_link('Edit')
    within('form') do
      fill_in 'app[name]', with: 'Application 2'
      fill_in 'app[redis_key]', with: 'vla1'
    end
    click_button 'Save'
    expect(page.current_path).to eq app_path(@app)
    expect(page).to have_content 'Apps'
    expect(page).to have_content 'Application 2'
    expect(page).to_not have_content 'Application 1'
  end

  it 'should show error when requirements not met' do
    visit apps_path
    click_link('Application 1')
    click_link('Edit')
    within('form') do
      fill_in 'app[name]', with: ''
    end
    click_button 'Save'
    expect(page.current_path).to eq app_path(@app)
    expect(page).to have_content 'Error'
  end

  it 'should do nothing when cancelled' do
    visit apps_path
    click_link('Application 1')
    click_link('Edit')
    within('form') do
      fill_in 'app[name]', with: 'Application 2'
      fill_in 'app[redis_key]', with: 'vla1'
    end
    click_link 'Cancel'
    expect(page.current_path).to eq app_path(@app)
    expect(page).to have_content 'Apps'
    expect(page).to have_content 'Application 1'
    expect(page).to_not have_content 'Application 2'
  end
end
