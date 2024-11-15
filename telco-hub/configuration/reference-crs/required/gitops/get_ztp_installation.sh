#! /bin/bash

# This script is only needed to create the ztp-installation manifest
# once per each Minor version.

CURRENT_OCP_VERSION=4.17
ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8:v${CURRENT_OCP_VERSION}
podman run --log-driver=none --rm registry.redhat.io/openshift4/${ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8} extract /home/ztp/argocd/deployment --tar | tar x -C "ztp-installation"
echo "Manifests created from ${ZTP_SITE_GENERATE_IMAGE}" > ztp-installation/manifests.ver
