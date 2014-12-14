# NAME: Captain Watcher
#
# DESCRIPTION: This image watches an etcd value to be set to the specified value and stops after that.
#
# REQUIRED ENVS: ETCD_ENDPOINT, ETCD_CA_CERTIFICATE, ETCD_CERTIFICATE_KEY, ETCD_CERTIFICATE, ETCD_KEY, ETCD_VALUE, REFRESH_TIME
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run -e ETCD_ENDPOINT "https://127.0.0.1:4001" -e ETCD_CA_CERTIFICATE="/path/to/ca_certificate"
# -e ETCD_CERTIFICATE="/path/to/certificate" -e ETCD_CERTIFICATE_KEY="/path/to/key" -e ETCD_KEY="/tds/doa3/containers/test/1/restart"
# -e ETCD_VALUE="1" -e REFRESH_TIME="2" thedutchselection/captain_watcher

FROM thedutchselection/captain_services_base:latest
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]