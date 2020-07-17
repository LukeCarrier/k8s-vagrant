#!/bin/sh

mkdir -p /etc/kubernetes/kube-vip

cat <<EOT >/etc/kubernetes/kube-vip/config.yaml
localPeer:
  id: ${LOCAL_PEER_ID}
  address: ${LOCAL_PEER_IP_ADDR}
  port: 10000
remotePeers:
${REMOTE_PEERS}
vip: ${APISERVER_VIP}
gratuitousARP: true
singleNode: false
startAsLeader: ${START_AS_LEADER}
interface: ${INTERFACE}
loadBalancers:
- name: API Server Load Balancer
  type: tcp
  port: ${APISERVER_FRONTEND_PORT}
  bindToVip: false
  backends:
${BACKENDS}
EOT

mkdir -p /etc/kubernetes/manifests

cat <<EOT >/etc/kubernetes/manifests/kube-vip.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - command:
    - /kube-vip
    - start
    - -c
    - /vip.yaml
    image: 'plndr/kube-vip:0.1.1'
    name: kube-vip
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - SYS_TIME
    volumeMounts:
    - mountPath: /vip.yaml
      name: config
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/kube-vip/config.yaml
    name: config
status: {}
EOT

if [ -n "$RESTART_KUBELET" ] && [ "$RESTART_KUBELET" = "1" ]; then
    systemctl restart kubelet
fi
