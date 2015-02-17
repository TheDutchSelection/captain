module UsersHelper
  
  def role_options
    options = []
    User.roles.each do |name, value|
      options << [t("models.user.roles.#{name}"), name]
    end
    options
  end

end
