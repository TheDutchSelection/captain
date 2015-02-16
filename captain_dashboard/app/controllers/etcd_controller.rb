class EtcdController < ApplicationController
  def index
    etcd = EtcdStorageService.new
    @etcd_tree = etcd.get
  end
end
