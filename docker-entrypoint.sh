#!/bin/bash

CONSUL_HTTP_ADDR=${ENV_CONSUL_HOST}:${ENV_CONSUL_PORT} consul services register -address=rabbitmq.${ENV_CLUSTER_NAMESPACE}.svc.cluster.local -name=rabbitmq.npool.top -port=5672
if [ ! $? -eq 0 ]; then
  echo "FAIL TO REGISTER ME TO CONSUL"
  exit 1
fi

/opt/bitnami/scripts/rabbitmq/entrypoint-inner.sh $@
