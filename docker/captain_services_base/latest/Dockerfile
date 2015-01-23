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

ADD files/opkg.conf /etc/opkg.conf

RUN opkg-install curl bash coreutils-stat

ADD files/scripts /usr/local/bin

ENTRYPOINT ["/bin/bash"]