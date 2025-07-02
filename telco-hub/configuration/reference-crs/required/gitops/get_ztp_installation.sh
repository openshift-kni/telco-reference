#! /bin/bash
set -euo pipefail

# This script is only needed to create the ztp-installation manifest
# once per each Minor version.

rm ztp-installation/*

# We create the manifestgs from the ztp-site-generate
CURRENT_OCP_VERSION=4.18
ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8:v${CURRENT_OCP_VERSION}
podman run --log-driver=none --rm registry.redhat.io/openshift4/${ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8} extract /home/ztp/argocd/deployment --tar | tar x -C "ztp-installation"
echo "Manifests created from  'registry.redhat.io/openshift4/${ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8}'"
echo "'registry.redhat.io/openshift4/${ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8}'" > ztp-installation/manifests.ver

# or, we create the manifests from the 'telco-ran/configuration/argocd/deployment/'"
#cp ../../../../../telco-ran/configuration/argocd/deployment/* ztp-installation/
#echo "Manifests created from 'telco-ran/configuration/argocd/deployment/'"

# some generated manifests are not needed
echo " - Removing some manifests not needed: allow-acm-managedcluster-control.json, disable-cluster-proxy-addon.json, openshift-gitops-operator.yaml"
rm ztp-installation/allow-acm-managedcluster-control.json ztp-installation/disable-cluster-proxy-addon.json ztp-installation/openshift-gitops-operator.yaml

