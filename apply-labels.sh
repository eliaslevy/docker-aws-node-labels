#!/bin/sh

MD="curl -s http://169.254.169.254/latest/meta-data/"
INSTANCE_ID=`${MD}/instance-id`
INSTANCE_TYPE=`${MD}/instance-type`
AVAILABILITY_ZONE=`${MD}/placement/availability-zone`

# It appears it takes a while for the hostname to incorporate the node name.
while [ "x$NODE" = "x" ] || [ "$NODE" = "null" ]; do
  sleep 1
  HOSTNAME=`hostname`
  echo Hostname: $HOSTNAME
  NODE=`curl  -s -f \
        --cert   /etc/kubernetes/ssl/worker.pem \
        --key    /etc/kubernetes/ssl/worker-key.pem \
        --cacert /etc/kubernetes/ssl/ca.pem  \
        ${CONTROLLER_ENDPOINT}/api/v1/namespaces/kube-system/pods/${HOSTNAME} | jq -r '.spec.nodeName'
  `
done

echo Node: $NODE

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
