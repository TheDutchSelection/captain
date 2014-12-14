# NAME: Captain Discoverer
#
# DESCRIPTION: This image takes care of writing the correct iptables file to a specific location
#
# REQUIRED ENVS: ETCD_ENDPOINT, ETCD_CA_CERTIFICATE, ETCD_CERTIFICATE_KEY, ETCD_CERTIFICATE, FILE_PATH, FILE_NAME, MODE,
# ETCD_BASE_PATH
#
# OPTIONAL ENVS: IPTABLES_RULE_[ID], ETCD_CURRENT_AVZONE_PATH, REFRESH_TIME
#
# USAGE EXAMPLE: docker run -e ETCD_ENDPOINT "https://127.0.0.1:4001" -e ETCD_CA_CERTIFICATE="/path/to/ca_certificate"
# -e ETCD_CERTIFICATE="/path/to/certificate" -e ETCD_CERTIFICATE_KEY="/path/to/key" -e FILE_PATH="/etc/iptables/"
# -e FILE_NAME="tds_iptable_rules" -e MODE="init" -e ETCD_BASE_PATH="/tds/" -e ETCD_CURRENT_AVZONE_PATH="/tds/doa3/hosts/"
# "thedutchselection/captain_iptables_discoverer

FROM thedutchselection/captain_services_base:1.0
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]