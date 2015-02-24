# NAME: CaptainDashboard
#
# DESCRIPTION: CaptainDashboard image which runs the captain dashboard application.
#
# REQUIRD ENVS: DATABASE, DATABASE_USER, DATABASE_PASSWORD, SECRET_KEY_BASE (production only), RAILS_ENV, ETCD_ENDPOINT,
# ETCD_BASE_PATH, ETCD_PREFIX
#
# OPTIONAL ENVS: UNICORN_WORKERS, DATABASE_AVZONE (if DATABASE_HOST or DATABASE_HOST_PORT are not defined),
# DATABASE_HOST (else POSTGRESQL_MASTER_[DATABASE_AVZONE_HOSTNAME]_HOST_PRIVATE_IP/_PUBLIC_IP must be defined), DATABASE_PORT
# (else POSTGRESQL_MASTER_[DATABASE_AVZONE_HOSTNAME]_HOST_PORT must be defined), ETCD_SSL_KEY, ETCD_SSL_CERT, ETCD_SSL_CACERT
#
# USAGE EXAMPLE: docker run -e DATABASE="captain_dashboard_development" -e DATABASE_USER="captain_dashboard"
# -e DATABASE_PASSWORD="abcd" -e DATABASE_HOST="10.0.4.5" -e DATABASE_PORT="5432" -e SECRET_KEY_BASE="abcd"
# -e RAILS_ENV="development" -e UNICORN_WORKERS="1" -e ETCD_ENDPOINT="http://127.0.0.1:2379" -e ETCD_BASE_PATH="/v2/keys/tds/"
# thedutchselection/captain_dashboard

FROM thedutchselection/app_env_captain_dashboard:latest
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

WORKDIR /tmp
ADD ./Gemfile /tmp/Gemfile
ADD ./Gemfile.lock /tmp/Gemfile.lock

RUN bundle install

ADD ./ /home/appmaster/application
ADD ./public /home/appmaster/application/public_original

RUN \
  chown -R appmaster:appmaster /home/appmaster

USER appmaster

ENV HOME /home/appmaster

WORKDIR /home/appmaster/application

ADD config/docker/files/scripts /usr/local/bin

EXPOSE 3000

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]