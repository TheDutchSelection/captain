require 'rails_helper'

RSpec.describe 'home', type: :feature do
  before do
    login_user
  end

  it 'should have all menu items' do
    visit '/'

    expect(page.current_path).to eq apps_path
    within '#main-nav' do
      expect(page).to have_content 'Apps'
      expect(page).to have_content 'Zones'
      expect(page).to have_content 'Etcd'
      expect(page).to have_content 'Logentries.com'
      expect(page).to have_content 'Alertmanager'
      expect(page).to have_content 'Promdash'
      expect(page).to have_content 'Users'
    end
  end
end
