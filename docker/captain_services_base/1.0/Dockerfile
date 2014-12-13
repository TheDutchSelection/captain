# NAME: Captain Services Base
#
# DESCRIPTION: A base for all services of captain.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE:

FROM progrium/busybox
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN opkg-install curl bash

ADD files/scripts /usr/local/bin

ENTRYPOINT ["/bin/bash"]