#!/bin/sh

MD="curl -s http://169.254.169.254/latest/meta-data/"
INSTANCE_ID=`${MD}/instance-id`
INSTANCE_TYPE=`${MD}/instance-type`
AVAILABILITY_ZONE=`${MD}/placement/availability-zone`
NODE=`curl  -s \
      --cert   /etc/kubernetes/ssl/worker.pem \
      --key    /etc/kubernetes/ssl/worker-key.pem \
      --cacert /etc/kubernetes/ssl/ca.pem  \
      ${CONTROLLER_ENDPOINT}/api/v1/namespaces/default/pods/${HOSTNAME} | jq -r '.spec.nodeName'
`

curl  -s \
      --cert   /etc/kubernetes/ssl/worker.pem \
      --key    /etc/kubernetes/ssl/worker-key.pem \
      --cacert /etc/kubernetes/ssl/ca.pem  \
      --request PATCH \
      -H "Content-Type: application/strategic-merge-patch+json" \
      -d @- \
      ${CONTROLLER_ENDPOINT}/api/v1/nodes/${NODE} <<EOF
{
  "metadata": {
    "labels": {
      "aws.node.kubernetes.io/id": "${INSTANCE_ID}",
      "aws.node.kubernetes.io/type": "${INSTANCE_TYPE}",
      "aws.node.kubernetes.io/az": "${AVAILABILITY_ZONE}"
    } 
  } 
}
EOF
