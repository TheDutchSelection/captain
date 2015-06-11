# NAME: CaptainDashboard
#
# DESCRIPTION: CaptainDashboard image which runs the captain dashboard application.
#
# REQUIRED ENVS:
# DATABASE (ie. "captain_dashboard_development")
# DATABASE_HOST (ie. "10.0.4.5")
# DATABASE_PORT (ie. "5432")
# DATABASE_USER (ie. "captain_dashboard")
# DATABASE_PASSWORD (ie. "abcd")
# REDIS_HOST (ie. "127.0.0.1")
# REDIS_PORT (ie. "6379")
# REDIS_DATABASE (ie. "0")
# REDIS_NAMESPACE (ie. "tds", : not allowed)
# SECRET_KEY_BASE (ie. "abcd")
# RAILS_ENV (ie. "development")
# UNICORN_WORKERS (ie. "1")
#
# OPTIONAL ENVS:
# REDIS_PASSWORD (ie. "abcdabcd")
#
# OTHER:

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