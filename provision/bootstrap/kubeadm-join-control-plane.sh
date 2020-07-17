#!/bin/sh

kubeadm join "$CONTROL_PLANE_ENDPOINT" \
    --v="$VERBOSITY" \
    --control-plane \
    --token "$TOKEN" \
    --discovery-token-ca-cert-hash "$DISCOVERY_TOKEN_CA_CERT_HASH" \
    --certificate-key "$CERTIFICATE_KEY"
