REDIS_STORAGE_SERVICE_DEFAULT_CONFIG =
  if ENV['REDIS_HOST'].present?
    if ENV['REDIS_PASSWORD'].present?
      { config: { url: "redis://:#{ENV['REDIS_PASSWORD']}@#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}/#{ENV['REDIS_DATABASE']}" }, namespace: ENV['REDIS_NAMESPACE'] }
    else
      { config: { url: "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}/#{ENV['REDIS_DATABASE']}" }, namespace: ENV['REDIS_NAMESPACE'] }
    end
  end

