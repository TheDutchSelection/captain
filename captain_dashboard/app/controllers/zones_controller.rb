class ZonesController < ApplicationController
  before_action :set_zone, only: [:edit, :show, :update, :destroy]

  def index
    @zones = Zone.all.order(name: :asc)
  end

  def show
  end

  def new
    @zone = Zone.new
  end

  def edit
  end

  def create
    @zone = Zone.new(zone_params)
    if @zone.save
      redirect_to zones_path
    else
      render :new
    end
  end

  def update
    if @zone.update(zone_params)
      redirect_to zone_path(@zone)
    else
      render :edit
    end
  end

  def destroy
    @zone.destroy
    redirect_to zones_url
  end

  private
    def set_zone
      @zone = Zone.find(params[:id])
    end

    def zone_params
      params[:zone].permit(:name, :redis_key)
    end
end
