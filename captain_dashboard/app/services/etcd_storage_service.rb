class EtcdStorageService

  def initialize(config = ETCD_STORAGE_SERVICE_DEFAULT_CONFIG)
    @config = config
    @etcd_connection = init_connection
  end

  def get(key = '')
    result = @etcd_connection.get("#{base_url(key)}", { recursive: 'true' }).body
    result = JSON.parse(result)
    if result['node'].has_key?('value')
      result = result['node']['value']
    end

    result
  rescue
    {}
  end

  def delete(key)
    @etcd_connection.delete("#{base_url(key)}", { recursive: 'true' })
  end

  def set(key, value)
    @etcd_connection.put("#{base_url(key)}", { value: value })
  end

  def get_servers_from_zone(zone_key, app_key = nil)
    []
  end

  private
  def init_connection
    if @config[:ssl_key].present? && @config[:ssl_cert].present? && @config[:ssl_cacert].present?
      etcd_connection = Faraday.new(
        @config[:endpoint],
        ssl: {
          client_cert: load_certificate(@config[:ssl_cert]),
          client_key: load_key(@config[:ssl_key]),
          ca_file: @config[:ssl_cacert]
        }
      )
    else
      etcd_connection = Faraday.new(@config[:endpoint])
    end
    
    etcd_connection
  end
  
  def base_url(key)
    "#{@config[:endpoint]}#{@config[:base_path]}#{key}"
  end

  def load_certificate(cert_file)
    raw = File.read(cert_file)
    OpenSSL::X509::Certificate.new raw
  end

  def load_key(key_file)
    raw = File.read(key_file)
    OpenSSL::PKey::RSA.new raw
  end
end
