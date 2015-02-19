module SessionsHelper
  def login_user
    user = FactoryGirl.create(:user, role: 'admin')
    login_as(user, scope: :user)
    user
  end
end
