class EtcdStorageService

  def initialize(config = ETCD_STORAGE_SERVICE_DEFAULT_CONFIG)
    @config = config
    @httparty_options = {
      pem: config[:pem_file],
      timeout: 300
    }
  end

  def get(key = '')
    options = @httparty_options.merge({ query: { recursive: 'true' } })
    result = ::HTTParty.get("#{base_url(key)}", options).to_json
    result = JSON.parse(result)

    if result['node'].has_key?('value')
      result = result['node']['value']
    end

    result
  rescue
    {}
  end

  def delete(key)
    options = @httparty_options.merge({ query: { recursive: 'true' } })
    ::HTTParty.delete("#{base_url(key)}", options)
  end

  def set(key, value)
    options = @httparty_options.merge({ query: { value: value } })
    ::HTTParty.put("#{base_url(key)}", options)
  end

  private
  def base_url(key)
    "#{@config[:endpoint]}#{@config[:base_path]}#{key}"
  end
end
