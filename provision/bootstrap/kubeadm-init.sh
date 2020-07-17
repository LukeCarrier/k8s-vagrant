#!/bin/sh

kubeadm init \
    --v="$VERBOSITY" \
    --apiserver-advertise-address "$APISERVER_ADVERTISE_ADDRESS" \
    --control-plane-endpoint "$CONTROL_PLANE_ENDPOINT" \
    --upload-certs
