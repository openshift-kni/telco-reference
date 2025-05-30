#! /usr/bin/env bash

# script to help you retrieve all the different versions
# of Subscriptions and other CRs that needs to change in
# every release
#

set -euo pipefail

# --- Configuration ---
# Allow overriding base directories with script arguments
# Usage: ./script.sh [config_dir] [install_dir]
ARG_CONFIG_BASE_DIR="${1:-./configuration/reference-crs}"
ARG_INSTALL_BASE_DIR="${2:-./install/mirror-registry}"

# Validate and set absolute paths for robustness if needed, or just use as is
CONFIG_BASE_DIR="$ARG_CONFIG_BASE_DIR"
INSTALL_BASE_DIR="$ARG_INSTALL_BASE_DIR"
# --- End Configuration ---

# Check for required tools
for tool in yq cat grep find; do # Consider if all are still needed if yq replaces some grep
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed. Please install $tool." >&2
    exit 1
  fi
done

print_section(){
  printf "\n###########################################################\n"
  printf "%s\n" "$1"
  printf "###########################################################\n\n"
}

check_file_exists() {
  local file_path="$1"
  local file_description="${2:-file}"
  if [[ ! -f "$file_path" ]]; then
    echo "Error: $file_description not found at $file_path" >&2
    return 1
  fi
  return 0
}

print_subscriptions(){
  print_section "Following a list of the different configured subscriptions in '$CONFIG_BASE_DIR'"
  # Using find ... -exec ... {} + is efficient and handles multiple files
  # It will output nothing if no matching files/content are found.
  # Add error handling if find itself fails (e.g. directory not found)
  find "$CONFIG_BASE_DIR/" -type f \( -name "*.yaml" -o -name "*.yml" \) \
    -exec yq -r 'select(.kind == "Subscription") | .metadata.name + " channel " + .spec.channel' {} + 2>/dev/null || {
      echo "No subscriptions found or an error occurred with find/yq in $CONFIG_BASE_DIR." >&2
      # Depending on desired behavior, you might want to return 1 here
    }
}

print_argocd_ztp_image(){
  print_section "ztp-site-generate version inside ArgoCD"
  local ztp_file="$CONFIG_BASE_DIR/required/gitops/ztp-installation/argocd-openshift-gitops-patch.json"

  if ! check_file_exists "$ztp_file" "ArgoCD ZTP patch file"; then return 1; fi

  # Using yq to look for a string; more robust would be a specific JSON path
  # This example tries to mimic the grep behavior somewhat but is safer
  # The exact yq query depends heavily on the JSON structure and what you want to extract.
  # This is a generic search for the string.
  local output
  output=$(yq '.. | select(type == "string" and contains("ztp-site-generator"))' "$ztp_file" 2>/dev/null)

  if [ -n "$output" ] && [ "$output" != "null" ]; then
    echo "$output"
  else
    # Fallback to grep if specific yq query is too complex or for exact original behavior
    # Make sure grep doesn't cause script to exit if no match
    grep "ztp-site-generator" "$ztp_file" || echo "ztp-site-generator string not found in $ztp_file"
  fi
}

print_disconnected_imageset_channels(){
  print_section "Disconnected imageset platform channels"
  local imageset_file="$INSTALL_BASE_DIR/imageset-config.yaml"

  if ! check_file_exists "$imageset_file" "Imageset config"; then return 1; fi

  # yq v4+ syntax for default value if path is null/missing
  yq '.mirror.platform.channels // "No platform channels found or path missing."' "$imageset_file"  2>/dev/null || {
    echo "Error processing platform channels in $imageset_file" >&2
  }
}

print_disconnected_imageset_operators(){
  print_section "Disconnected imageset version of operators"
  local imageset_file="$INSTALL_BASE_DIR/imageset-config.yaml"

  if ! check_file_exists "$imageset_file" "Imageset config"; then return 1; fi

  local output
  output=$(yq '.mirror.operators[].packages[] | .name + " " + .channels[].name' "$imageset_file" 2>/dev/null)

  if [ -n "$output" ] && [ "$output" != "null" ]; then
    echo "$output"
  else
    echo "No operator packages or channels found, or path missing in $imageset_file."
  fi
}

print_agentservice_images(){
  print_section "AgentServiceConfig configured images"
  local agentservice_file="$CONFIG_BASE_DIR/required/acm/acmAgentServiceConfig.yaml"

  if ! check_file_exists "$agentservice_file" "AgentServiceConfig"; then return 1; fi

  local output
  output=$(yq '.spec.osImages[].openshiftVersion' "$agentservice_file" 2>/dev/null)

  if [ -n "$output" ] && [ "$output" != "null" ]; then
    echo "$output"
  else
    echo "No osImages found or path missing in $agentservice_file."
  fi
}

# --- Main execution ---
echo "Retrieving versions from:"
echo "Config Dir: $CONFIG_BASE_DIR"
echo "Install Dir: $INSTALL_BASE_DIR"

print_subscriptions
print_argocd_ztp_image
print_disconnected_imageset_channels
print_disconnected_imageset_operators
print_agentservice_images

echo -e "\nFinished."

