#!/bin/bash
set -e

# Remove pid
rm -f /home/appmaster/application/unicorn.pid

# Copy original public files to public folder
cp -Rp /home/appmaster/application/public_original/* /home/appmaster/application/public/

echo "precompiling..."
bundle exec rake assets:precompile

echo "migrating database..."
bundle exec rake db:create db:migrate

echo "starting application as webserver..."
exec bundle exec unicorn_rails -c /home/appmaster/application/config/unicorn.rb

