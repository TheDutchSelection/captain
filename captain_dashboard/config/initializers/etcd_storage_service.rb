ETCD_STORAGE_SERVICE_DEFAULT_CONFIG =
  {
    ssl_key: ENV['ETCD_CERTIFICATE_KEY'],
    ssl_cert: ENV['ETCD_CERTIFICATE'],
    ssl_cacert: ENV['ETCD_CA_CERTIFICATE'],
    endpoint: ENV['ETCD_ENDPOINT'],
    base_path: ENV['ETCD_BASE_PATH'],
    prefix: ENV['ETCD_PREFIX']
  }