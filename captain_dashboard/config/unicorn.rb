if !ENV['UNICORN_WORKERS'].nil?
  worker_processes ENV['UNICORN_WORKERS'].to_i
else
  worker_processes 1
end

if ENV['RAILS_ENV'] == 'production'
  pid '/home/appmaster/application/unicorn.pid'
  listen 3000, :tcp_nopush => true
end

timeout 30