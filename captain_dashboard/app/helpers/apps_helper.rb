module AppsHelper
  
  def server_list(zone, app = nil)
    servers = zone.servers(app).sort_by!{ |e| e.downcase }
    servers.join(', ')
  end

end
