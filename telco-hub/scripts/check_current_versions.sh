#! /bin/bash

# script to help you retrieve all the different versions
# of Subscriptions and other CRs that needs to change in
# every release
#

set -euo pipefail

# Check for required tools
for tool in yq cat grep find; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed." >&2
    exit 1
  fi
done

print_section(){
  printf "\n###########################################################\n"
  printf "%s\n" "$1"
  printf "###########################################################\n\n"

}
print_subscriptions(){
  print_section "Following a list of the different configured subscriptions"

  find ./configuration/reference-crs/ -type f \( -name "*.yaml" -o -name "*.yml" \) \
      | xargs cat - \
      | yq -r 'select(.kind == "Subscription") | .metadata.name + " channel " + .spec.channel'
}

print_argocd_ztp_image(){
  print_section "ztp-site-generate version inside ArgoCD"

  grep ztp-site-generator ./configuration/reference-crs/required/gitops/ztp-installation/argocd-openshift-gitops-patch.json || true
}

print_disconnected_imageset_channels(){
  print_section "Disconnected imageset platform channels"

  yq '.mirror.platform.channels' ./install/mirror-registry/imageset-config.yaml
}

print_disconnected_imageset_operators(){
  print_section "Disconnected imageset version of operators"

  yq '.mirror.operators[].packages[] | .name + " " + .channels[].name' ./install/mirror-registry/imageset-config.yaml
}

print_agentservice_images(){
  print_section "AgentServiceConfig configured images"

  yq '.spec.osImages[].openshiftVersion'  ./configuration/reference-crs/required/acm/acmAgentServiceConfig.yaml
}

print_subscriptions
print_argocd_ztp_image
print_disconnected_imageset_channels
print_disconnected_imageset_operators
print_agentservice_images
