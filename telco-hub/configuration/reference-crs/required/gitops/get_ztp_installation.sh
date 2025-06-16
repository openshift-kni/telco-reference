#! /bin/bash

# This script is only needed to create the ztp-installation manifest
# once per each Minor version.

#CURRENT_OCP_VERSION=4.18
#ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8:v${CURRENT_OCP_VERSION}
#podman run --log-driver=none --rm registry.redhat.io/openshift4/${ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8} extract /home/ztp/argocd/deployment --tar | tar x -C "ztp-installation"

rm ztp-installation/*
cp ../../../../../telco-ran/configuration/argocd/deployment/* ztp-installation/
echo "Manifests created from 'telco-ran/configuration/argocd/deployment/'"
# some generated manifests are not needed
echo " - Removing some manifests not needed: allow-acm-managedcluster-control.json, disable-cluster-proxy-addon.json, openshift-gitops-operator.yaml"
rm ztp-installation/allow-acm-managedcluster-control.json ztp-installation/disable-cluster-proxy-addon.json ztp-installation/openshift-gitops-operator.yaml

# following changes are temporal, these should come from the original source
# we add some needed waves
echo " - Adding ztp-waves."
find ./ztp-installation/ -name "*.yaml" -exec yq -i eval '.metadata.annotations."argocd.argoproj.io/sync-wave" = "100"' {} \;

# patch the ztp-site-generate version
echo " - Patch ztp-site-generate version"
sed -i 's|quay.io/openshift-kni/ztp-site-generator:latest|registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.19|g' ztp-installation/argocd-openshift-gitops-patch.json

