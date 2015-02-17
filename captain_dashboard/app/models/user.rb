class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  enum role: [:member, :admin]
  
  default_scope { order(email: :asc) }

end
