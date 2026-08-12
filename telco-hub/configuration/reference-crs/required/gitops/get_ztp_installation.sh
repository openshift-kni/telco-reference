#! /bin/bash

if sed --version 2>/dev/null | grep -q GNU; then
  sedi() { sed -i "$@"; }
else
  sedi() { sed -i '' "$@"; }
fi

# This script is only needed to create the ztp-installation manifest
# once per each Minor version.

#CURRENT_OCP_VERSION=4.18
#ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8:v${CURRENT_OCP_VERSION}
#podman run --log-driver=none --rm registry.redhat.io/openshift4/${ZTP_SITE_GENERATE_IMAGE=ztp-site-generate-rhel8} extract /home/ztp/argocd/deployment --tar | tar x -C "../../../argocd/deployment"

rm ../../../argocd/deployment/*
cp ../../../../../telco-ran/configuration/argocd/deployment/* ../../../argocd/deployment/
echo "Manifests created from 'telco-ran/configuration/argocd/deployment/'"
# some generated manifests are not needed
echo " - Removing some manifests not needed: allow-acm-managedcluster-control.json, disable-cluster-proxy-addon.json, openshift-gitops-operator.yaml"
rm ../../../argocd/deployment/allow-acm-managedcluster-control.json ../../../argocd/deployment/disable-cluster-proxy-addon.json ../../../argocd/deployment/openshift-gitops-operator.yaml

# following changes are temporal, these should come from the original source
# we add some needed waves
echo " - Adding ztp-waves."
find ../../../argocd/deployment/ -name "*.yaml" -exec yq -i eval '.metadata.annotations."argocd.argoproj.io/sync-wave" = "100"' {} \;

# patch the ztp-site-generate version
echo " - Patch ztp-site-generate version"
sedi 's|quay.io/openshift-kni/ztp-site-generator:latest|registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.21|g' ../../../argocd/deployment/argocd-openshift-gitops-patch.json

echo  " - Adding elements to the whitelist"
yq '.spec.namespaceResourceWhitelist += {"group": "'metal3.io'", "kind": "DataImage"}' ../../../argocd/deployment/app-project.yaml
yq '.spec.namespaceResourceWhitelist += {"group": "'extensions.hive.openshift.io'", "kind": "ImageClusterInstall"}' ../../../argocd/deployment/app-project.yaml
