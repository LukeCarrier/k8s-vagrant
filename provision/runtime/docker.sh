#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

apt-get install -y \
    apt-transport-https ca-certificates curl gnupg2 \
    software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) \
    stable"

apt-get update
apt-get install -y --allow-downgrades \
    containerd.io=1.2.13-2 \
    docker-ce=5:19.03.11~3-0~debian-$(lsb_release -cs) \
    docker-ce-cli=5:19.03.11~3-0~debian-$(lsb_release -cs)

cat >/etc/docker/daemon.json <<EOF
{
  "exec-opts": [
    "native.cgroupdriver=systemd"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl restart docker
