# NAME: Captain Container Exporter
#
# DESCRIPTION: This image exports a container volume to a tarball and saves it. It can also upload it to AWS S3.
#
# REQUIRED ENVS:
# DATA_CONTAINER_VOLUME (ie. "/home/postgresql/data")
# TAR_BASE_FILENAME (ie. "postgresql_data" creates files called postgresql_data_[timestamp].tar)
# EXECUTION_TIME (ie. "16:00")
#
# OPTIONAL ENVS:
# AWS_S3_ACCESS_KEY_ID (ie. "abcdabcd1234")
# AWS_S3_SECRET_ACCESS_KEY (ie. "abcdabcd1234")
# AWS_S3_BUCKET_NAME (ie. "tds-backups")
# AWS_S3_BUCKET_REGION  (ie. "eu-central-1")
# AWS_S3_PATH (ie. "containers/jenkins_data/" ending with a slash)
#
# OTHER:
# mount the docker.sock from the host into this container for jenkins to be able to run docker commands, ie.
# -v /var/run/docker.sock:/var/run/docker.sock.
#
# also use the --volumes-from from the data_container
#
# To restore a volume use something like:
# docker run --volumes-from postgresql_data --entrypoint "tar" -v $(pwd):/backup thedutchselection/captain_container_volume_exporter xvf /backup/backup.tar

FROM thedutchselection/captain_services_base:latest
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk-install curl && \
  apk-install docker

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/*

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]