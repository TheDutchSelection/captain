module AppsHelper
  
  def server_list(zone, app = nil)
    zone.servers(app).join(', ')
  end

end
