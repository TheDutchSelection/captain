class EtcdStorageService

  ETCD_FALSE_VALUE = 0
  ETCD_NEED_RESTART_KEY = 'need_restart'
  ETCD_TRUE_VALUE = 1
  ETCD_UPDATE_KEY = 'update'

  def initialize(config = ETCD_STORAGE_SERVICE_DEFAULT_CONFIG)
    @config = config
    @etcd_connection = init_connection
  end

  def get(key = '')
    response = @etcd_connection.get do |req|
      req.url "#{base_url(key)}"
      req.params['recursive'] = 'true'
    end
    result = response.body
    result = JSON.parse(result)
    if result['node'].has_key?('value')
      result = result['node']['value']
    end

    result
  rescue
    {}
  end

  def delete(key)
    @etcd_connection.delete do |req|
      req.url "#{base_url(key)}"
      req.params['recursive'] = 'true'
    end
  end

  def set(key, value, include_prefix = true)
    response = @etcd_connection.put do |req|
      req.url "#{base_url(key, include_prefix)}"
      req.params['value'] = value
    end
    result = response.body
    JSON.parse(result)
  rescue
    ''
  end

  def set_app_key_in_zone(zone_key, app_key, key, value)
    result = false
    zone_hash = get(zone_key)['node']
    containers_hash = get_hash_from_zone_hash(zone_hash, :containers)
    containers_hash['nodes'].each do |app|
      if app['key'].split('/')[-1].start_with?(app_key)
        app['nodes'].each do |app_server|
          app_server['nodes'].each do |key_value|
            if key_value['key'].split('/')[-1] == key
              result = set(key_value['key'], value, false)
            end
          end
        end
      end
    end

    result
  rescue
    false
  end

  def get_servers_from_zone(zone_key, app_key = nil)
    result = []
    zone_hash = get(zone_key)['node']
    if app_key.present?
      containers_hash = get_hash_from_zone_hash(zone_hash, :containers)
      containers_hash['nodes'].each do |container|
        if container['key'].split('/')[-1].start_with?(app_key)
          container['nodes'].each do |server|
            host_name = server['key'].split('/')[-1]
            result.push(host_name)
          end
        end
      end
    else
      hosts_hash = get_hash_from_zone_hash(zone_hash, :hosts)
      hosts_hash['nodes'].each do |host|
        host_name = host['key'].split('/')[-1]
        result.push(host_name)
      end
    end

    result
  rescue
    []
  end

  private
    def init_connection
      if @config[:ssl_key].present? && @config[:ssl_cert].present? && @config[:ssl_cacert].present?
        etcd_connection = Faraday.new(
          @config[:endpoint],
          request: {
            timeout: 30,
            open_timeout: 30
          },
          ssl: {
            client_cert: load_certificate(@config[:ssl_cert]),
            client_key: load_key(@config[:ssl_key]),
            ca_file: @config[:ssl_cacert]
          }
        )
      else
        etcd_connection = Faraday.new(
          @config[:endpoint],
          request: {
            timeout: 30,
            open_timeout: 30
          }
        )
      end

      etcd_connection
    end

    def base_url(key, include_prefix = true)
      if include_prefix
        "#{@config[:endpoint]}#{@config[:base_path]}#{@config[:prefix]}#{key}"
      else
        "#{@config[:endpoint]}#{@config[:base_path]}#{key}"
      end

    end

    def load_certificate(cert_file)
      raw = File.read(cert_file)
      OpenSSL::X509::Certificate.new raw
    end

    def load_key(key_file)
      raw = File.read(key_file)
      OpenSSL::PKey::RSA.new raw
    end

    def get_hash_from_zone_hash(zone_hash, type)
      zone_key = zone_hash['key']
      result = {}
      zone_hash['nodes'].each do |hash|
        if hash.has_key?('key') && hash['key'] == "#{zone_key}/#{type.to_s}"
          result = hash
          break
        end
      end

      result
    end
end
