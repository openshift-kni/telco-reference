#!/bin/bash
#
# This script is designed to update file references within this project.
# It should be run from the 'configuration' subdirectory.
# It finds all '*.yaml' files under 'source-crs' and ensures that any
# references to these files use a consistent, full path relative to the
# 'configuration' directory.
#
# WARNING: This script performs in-place file modifications.
# It is crucial to run this in a version-controlled environment and
# to carefully review all changes before committing.

set -euo pipefail

if [[ ! -d "source-crs" ]]; then
  echo "Error: This script must be run from a directory containing 'source-crs' (e.g., the 'configuration' directory)." >&2
  exit 1
fi

# Find all .yaml files in the source-crs directory and store them in an array.
readarray -t target_files < <(find source-crs -name "*.yaml")

# Iterate through the array of target files.
for target_path in "${target_files[@]}"; do
  if [[ ! -f "$target_path" ]]; then
    echo "Warning: File not found, skipping: $target_path"
    continue
  fi

  file_name=$(basename "$target_path")
  replacement_path="${target_path#source-crs/}"
  # Escape the filename for use in sed regex (for the '.')
  escaped_file_name=$(echo "$file_name" | sed 's/\./\\./g')

  echo "Processing references for '$file_name', ensuring path is '$replacement_path'"

  # Find all text files that contain the filename as a whole word,
  # searching only within the 'argocd' directory, and store them in an array.
  readarray -t found_files < <(grep -rlw --exclude-dir=".git" --exclude="$(basename "$0")" "$file_name" argocd || true)

  # Iterate through the array of files that contain references.
  for found_file in "${found_files[@]}"; do
    # Skip the target file itself.
    if [[ "$(realpath "$found_file")" == "$(realpath "$target_path")" ]]; then
      continue
    fi

    echo "  Updating references in: $found_file"

    # Choose the replacement strategy based on the file's content.
    if grep -q "source-crs/.*$file_name" "$found_file"; then
      # This file contains an incorrect 'source-crs' path. Fix it.
      sed -i -e "s|source-crs/[^[:space:]\`[]*${escaped_file_name}|source-crs/$replacement_path|g" "$found_file"
    else
      # This file contains a different incorrect full path. Fix it.
      # This regex finds a path-like string ending in the filename.
      replacement_path=${replacement_path#%source-crs/}
      sed -i -e "s|[^[:space:]\`[]*${escaped_file_name}|${replacement_path}|g" "$found_file"
    fi
  done
done

echo "Script finished. Please review the changes made."
