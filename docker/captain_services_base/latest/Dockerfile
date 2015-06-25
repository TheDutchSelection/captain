# NAME: Captain Services Base
#
# DESCRIPTION: Captain Services Base.
#
# REQUIRED ENVS:
# REDIS_HOST (ie. 127.0.0.1)
# REDIS_PORT (ie. 6379)
# REDIS_DATABASE (ie. 0)
# REDIS_NAMESPACE (ie. "tds", : not allowed)
#
# OPTIONAL ENVS:
# REDIS_PASSWORD (ie. abcdabcd)
#
# OTHER:

FROM gliderlabs/alpine:3.2
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN apk-install bash

RUN \
  apk-install redis && \
  rm /etc/conf.d/redis && \
  rm /etc/logrotate.d/redis && \
  rm /etc/init.d/redis && \
  rm /etc/redis.conf && \
  rm /usr/share/licenses/redis/COPYING && \
  rm /usr/bin/redis-sentinel && \
  rm /usr/bin/redis-server && \
  rm /usr/bin/redis-benchmark && \
  rm /usr/bin/redis-check-dump && \
  rm /usr/bin/redis-check-aof

ADD files/scripts /usr/local/bin

ENTRYPOINT ["/bin/bash"]