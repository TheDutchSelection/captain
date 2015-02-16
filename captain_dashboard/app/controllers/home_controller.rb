class HomeController < ApplicationController
  def index
    redirect_to etcd_path
  end
end
