#! /bin/bash

# This script is only needed to create the ztp-installation manifest
# once per each Minor version.

#CURRENT_OCP_VERSION=4.18
#ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8:v${CURRENT_OCP_VERSION}
#podman run --log-driver=none --rm registry.redhat.io/openshift4/${ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8} extract /home/ztp/argocd/deployment --tar | tar x -C "ztp-installation"
# some generated manifests are not needed
#rm ztp-installation/allow-acm-managedcluster-control.json ztp-installation/disable-cluster-proxy-addon.json ztp-installation/openshift-gitops-operator.yaml

rm ztp-installation/*
cp ../../../../../telco-ran/configuration/argocd/deployment/* ztp-installation/
echo "Manifests created from 'telco-ran/configuration/argocd/deployment/'"
