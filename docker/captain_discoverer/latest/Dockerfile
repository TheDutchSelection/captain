# NAME: Captain Discoverer
#
# DESCRIPTION: This image takes care of discovery of new values. When in "init" mode it creates the initial environment
# file, when in "watch" mode, it creates an temp environment file every x seconds and compares it with the initial environment
# file, if they differ, this container sets the specified "need restart" key to 1.
#
# REQUIRED ENVS: ETCD_ENDPOINT, ETCD_CA_CERTIFICATE, ETCD_CERTIFICATE_KEY, ETCD_CERTIFICATE, ETCD_BASE_PATH, MODE, FILE_PATH,
# FILE_NAME, APP_KEYS, ETCD_CURRENT_APP, ETCD_CURRENT_AVZONE_PATH
#
# OPTIONAL ENVS: REFRESH_TIME (only in watch mode), NEED_RESTART_KEY (only in watch mode), IGNORED_APP_KEY
# ETCD_CACHE_SECONDS, ETCD_CACHE_FILE
#
# USAGE EXAMPLE: docker run -e ETCD_ENDPOINT "https://127.0.0.1:4001" -e ETCD_CA_CERTIFICATE="/path/to/ca_certificate"
# -e ETCD_CERTIFICATE="/path/to/certificate" -e ETCD_CERTIFICATE_KEY="/path/to/key" -e ETCD_BASE_PATH="/tds/"
# -e MODE="watch" -e REFRESH_TIME="45" -e FILE_PATH="/root/doa3/tds/containers/test/1" -e FILE_NAME="current-containers-env"
# -e APP_KEYS="test/ test_2/" -e IGNORED_APP_KEY="test/1/" -e NEED_RESTART_KEY "need_restart" -e ETCD_CURRENT_APP="test/1/"
# -e ETCD_CURRENT_AVZONE_PATH="/tds/doa3/containers/" thedutchselection/captain_discoverer

FROM thedutchselection/captain_services_base:latest
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]