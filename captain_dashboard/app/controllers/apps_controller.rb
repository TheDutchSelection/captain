class AppsController < ApplicationController
  before_action :set_app, only: [:edit, :show, :update, :destroy, :set_key_in_zone]
  before_action :set_zones, only: [:new, :edit, :update, :create]

  def index
    @apps = App.all.order(name: :asc)
  end

  def show
  end

  def new
    @app = App.new
  end

  def edit
  end

  def create
    @app = App.new(app_params)
    if @app.save
      redirect_to apps_path
    else
      render :new
    end
  end

  def update
    if @app.update(app_params)
      redirect_to app_path(@app)
    else
      render :edit
    end
  end

  def set_key_in_zone
    zone = Zone.find(params[:zone_id])
    @app.set_key_in_zone(zone, params[:key], params[:value])
    redirect_to app_path(@app)
  end

  def destroy
    @app.destroy
    redirect_to apps_url
  end

  private
    def set_app
      @app = App.find(params[:id])
    end

    def set_zones
      @zones = Zone.all.order(name: :asc)
    end

    def app_params
      params[:app].permit(:name, :redis_key, zone_ids: [])
    end
end