# NAME: Captain Value Setter
#
# DESCRIPTION: This image sets values to etcd.
#
# REQUIRED ENVS: ETCD_ENDPOINT, ETCD_CA_CERTIFICATE, ETCD_CERTIFICATE_KEY, ETCD_CERTIFICATE, ETCD_BASE_PATH, ETCD_SHORT_KEYS_VALUES
#
# OPTIONAL ENVS: ETCD_CACHE_SECONDS, ETCD_CACHE_FILE
#
# USAGE EXAMPLE: docker run -e ETCD_ENDPOINT "https://127.0.0.1:4001" -e ETCD_CA_CERTIFICATE="/path/to/ca_certificate"
# -e ETCD_CERTIFICATE="/path/to/certificate" -e ETCD_CERTIFICATE_KEY="/path/to/key" -e ETCD_BASE_PATH="/tds/doa3/containers/test/1/"
# -e ETCD_KEYS_VALUES="need_restart##0  update##0 restart##0" thedutchselection/captain_value_setter

FROM thedutchselection/captain_services_base:latest
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]