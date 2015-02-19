class HomeController < ApplicationController
  def index
    redirect_to zones_path
  end
end
