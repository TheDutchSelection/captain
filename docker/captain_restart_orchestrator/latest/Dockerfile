# NAME: Captain Restart Orchestrator
#
# DESCRIPTION: This image sets the restart keys for the containers that have the need_restart key set. By default it
# sets 1 restart key at once, except for the exception keys.
#
# REQUIRED ENVS: ETCD_ENDPOINT, ETCD_CA_CERTIFICATE, ETCD_CERTIFICATE_KEY, ETCD_CERTIFICATE, ETCD_BASE_PATH, ETCD_RESTART_KEY_VALUE,
# ETCD_NEED_RESTART_KEY_VALUE, APP_EXCEPTIONS, REFRESH_TIME
#
# OPTIONAL ENVS: ETCD_CACHE_SECONDS, ETCD_CACHE_FILE
#
# USAGE EXAMPLE: docker run -e ETCD_ENDPOINT "https://127.0.0.1:4001" -e ETCD_CA_CERTIFICATE="/path/to/ca_certificate"
# -e ETCD_CERTIFICATE="/path/to/certificate" -e ETCD_CERTIFICATE_KEY="/path/to/key" -e ETCD_BASE_PATH="/tds/doa3/containers/"
# -e ETCD_RESTART_KEY_VALUE="restart##1" -e ETCD_NEED_RESTART_KEY_VALUE="need_restart##1"
# -e APP_EXCEPTIONS="test/##2 test2/##4" -e REFRESH_TIME="15" thedutchselection/captain_restart_orchestrator

FROM thedutchselection/captain_services_base:latest
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]