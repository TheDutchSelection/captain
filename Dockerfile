# NAME: Captain
#
# DESCRIPTION: Captain updates docker images and restarts app services. A client
# can call
# [host]:[port]/update/?env=production&app=[app]&docker_image_tag=[docker_image_tag]&docker_image_name=[docker_image_name]&probe_path=[probe_path]
# and then captain will search on all app servers for the app and pull the
# docker image and restart the app services. probe_path is optional and if given
# Captain will wait till the path returns a 200 and then restart the next
# container
#
# REQUIRED ENVS:
# APP_SERVERS_[ENV] (ie. "10.0.0.1 10.0.0.2")
# DOCKER_REGISTRY_HOST (ie. "hub.docker.com")
# DOCKER_REGISTRY_PORT (ie. 80)
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/alpine:3.8
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add bash && \
  apk add python3 && \
  apk add python3-dev && \
  apk add build-base && \
  apk add libffi-dev && \
  apk add openssl-dev && \
  rm /var/cache/apk/* && \
  python3 -m ensurepip && \
  rm -r /usr/lib/python*/ensurepip && \
  pip3 install --upgrade pip setuptools && \
  if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
  if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
  rm -r /root/.cache && \
  adduser -D -u 8765 captain

ADD ./ /home/captain/application

RUN \
  chown -R captain:captain /home/captain

RUN \
  pip3 install -r /home/captain/application/requirements.txt

USER captain

WORKDIR /home/captain/application

EXPOSE 15621

ENTRYPOINT ["python3", "captain.py"]
