FROM docker.io/bitnami/rabbitmq:3.9.7-debian-10-r0

RUN mkdir -p /usr/local/bin
RUN mv /opt/bitnami/scripts/rabbitmq/entrypoint.sh /opt/bitnami/scripts/rabbitmq/entrypoint-inner.sh
RUN mv /opt/bitnami/scripts/rabbitmq/run.sh /opt/bitnami/scripts/rabbitmq/run-inner.sh

USER root
RUN apt-get update -y
RUN apt-get install curl -y

COPY .docker-tmp/consul /usr/bin/consul
COPY docker-entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
