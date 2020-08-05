#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get dist-upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
