#!/bin/sh

kubeadm join "$CONTROL_PLANE_ENDPOINT" \
    --token "$TOKEN" \
    --discovery-token-ca-cert-hash "$DISCOVERY_TOKEN_CA_CERT_HASH"
