# NAME: Captain Publisher
#
# DESCRIPTION: This image takes care of publishing values to etcd. All ENVS starting with ETCD_VALUE_[NAME] are
# converted to name and appended to the ETCD_BASE_PATH.
#
# REQUIRED ENVS: ETCD_ENDPOINT, ETCD_CA_CERTIFICATE, ETCD_CERTIFICATE_KEY, ETCD_CERTIFICATE, ETCD_BASE_PATH, ETCD_TTL, REFRESH_TIME
#
# OPTIONAL ENVS: ETCD_VALUE_[NAME]
#
# USAGE EXAMPLE: docker run -e ETCD_ENDPOINT "https://127.0.0.1:4001" -e ETCD_CA_CERTIFICATE="/path/to/ca_certificate"
# -e ETCD_CERTIFICATE="/path/to/certificate" -e ETCD_CERTIFICATE_KEY="/path/to/key" -e ETCD_BASE_PATH="/tds/doa3/containers/test/1/"
# -e ETCD_TTL="120" -e REFRESH_TIME="45" -e ETCD_VALUE_HOST_PRIVATE_IP="10.0.0.1" -e ETCD_VALUE_PORT="3001" thedutchselection/captain_publisher

FROM thedutchselection/captain_services_base:1.0
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]