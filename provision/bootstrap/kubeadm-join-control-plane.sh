#!/bin/sh

kubeadm join "$CONTROL_PLANE_ENDPOINT" \
    --v="$VERBOSITY" \
    --control-plane \
    --certificate-key "$CERTIFICATE_KEY" \
    --discovery-token-ca-cert-hash "$DISCOVERY_TOKEN_CA_CERT_HASH" \
    --token "$TOKEN" \
    --apiserver-advertise-address "$APISERVER_ADVERTISE_ADDRESS"
