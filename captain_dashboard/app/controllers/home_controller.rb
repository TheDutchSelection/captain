class HomeController < ApplicationController
  def index
    redirect_to apps_path
  end
end
