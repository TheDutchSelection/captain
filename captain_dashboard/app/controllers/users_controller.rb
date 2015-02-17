class UsersController < BackendController
  # before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = User.all
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path
    end
    render :new
  end
  
  def edit
  end
  
  def update
    if @user.update(user_params)
      redirect_to users_path
    end
    render :edit
  end
  
  def destroy
    @user.destroy
    redirect_to users_path
  end

  def password
    if params[:user] && @user.update(user_params)
      redirect_to user_path(@user)
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params[:user].permit(:email, :password, :password_confirmation, :role)
    end

end
