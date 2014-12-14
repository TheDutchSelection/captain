# NAME: Captain Pull Messenger
#
# DESCRIPTION: This image echo's the pull command if a pull is necessary or a blank line if nothing needs to happen You can
# eval this outcome like this eval "$(docker run thedutchselection/captain_pull_messenger:1.0)"
#
# REQUIRED ENVS: ETCD_ENDPOINT, ETCD_CA_CERTIFICATE, ETCD_CERTIFICATE_KEY, ETCD_CERTIFICATE, IMAGE_COMPLETE, ETCD_KEY, ETCD_NO_PULL_VALUE
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run -e ETCD_ENDPOINT "https://127.0.0.1:4001" -e ETCD_CA_CERTIFICATE="/path/to/ca_certificate"
# -e ETCD_CERTIFICATE="/path/to/certificate" -e ETCD_CERTIFICATE_KEY="/path/to/key" -e ETCD_KEY="/tds/doa3/containers/test/1/update"
# -e ETCD__NO_PULL_VALUE="0" thedutchselection/captain_pull_messenger

FROM thedutchselection/captain_services_base:latest
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]