#! /bin/bash

# script to help you retrieve all the different versions
# of Subscriptions and other CRs that needs to change in
# every release
#

echo "###########################################################"
echo "Following a list of the different configured subscriptions "
echo "###########################################################"
echo -e

find ./configuration/reference-crs/ -type f \( -name "*.yaml" -o -name "*.yml" \) | xargs cat - | yq -r ' select(.kind == "Subscription") | .metadata.name + " channel " + .spec.channel'

echo -e
echo "###########################################################"
echo "ztp-site-generate version inside ArgoCD "
echo "###########################################################"
echo -e

cat ./configuration/reference-crs/required/gitops/ztp-installation/argocd-openshift-gitops-patch.json |  grep ztp-site-generator

echo -e
echo "###########################################################"
echo "Disconnected imageset platform channels "
echo "###########################################################"
echo -e

yq '.mirror.platform.channels' ./install/mirror-registry/imageset-config.yaml

echo -e
echo "###########################################################"
echo "Disconnected imageset version of operators "
echo "###########################################################"
echo -e

yq '.mirror.operators[].packages[] | .name + " " + .channels[].name' ./install/mirror-registry/imageset-config.yaml

echo -e
echo "###########################################################"
echo "AgentServiceConfig configured images"
echo "###########################################################"
echo -e

yq '.spec.osImages[].openshiftVersion'  ./configuration/reference-crs/required/acm/acmAgentServiceConfig.yaml

