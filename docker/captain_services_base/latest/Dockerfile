# NAME: Captain Services Base
#
# DESCRIPTION: A base for all services of captain.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE:

FROM gliderlabs/alpine:3.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN apk-install curl bash

ADD files/scripts /usr/local/bin

RUN \
  chmod +x /usr/local/bin/jq

ENTRYPOINT ["/bin/bash"]