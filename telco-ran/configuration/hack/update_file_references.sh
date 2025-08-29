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

if [[ $# == 0 || $1 == "--help" || $1 == "-h" ]]; then
  echo "Usage:"
  echo "  $(basename "$0") [target...]"
  echo
  echo "Processes the directory structure under source-crs, and then visits"
  echo "every target file (or all files in each target directory) and updates"
  echo "all paths to match the source-crs directory structure."
  exit 1
fi

# Find all .yaml files in the source-crs directory and store them in an array.
readarray -t source_files < <(find source-crs -name "*.yaml")

# Iterate through the array of target files.
for source_file in "${source_files[@]}"; do
  if [[ ! -f "$source_file" ]]; then
    echo "Warning: File not found, skipping: $source_file"
    continue
  fi

  file_name=$(basename "$source_file")
  replacement_path="${source_file#source-crs/}"
  # Escape the filename for use in sed regex (for the '.')
  escaped_file_name=${file_name//\./\\.}

  echo "Processing references for '$file_name', ensuring path is '$replacement_path'"

  target_files=()
  # Find all text files that contain the filename as a whole word,
  # searching in all target directories, and store them in an array.
  for target in "$@"; do
    if [[ -d $target ]]; then
      readarray -t -O "${#target_files[@]}" target_files < <(grep -rlw --exclude-dir=".git" --exclude="$(basename "$0")" "$file_name" "$target" || true)
    else
      target_files+=("$target")
    fi
  done

  # Iterate through the array of files that contain references.
  for target_file in "${target_files[@]}"; do
    # Skip the target file itself.
    if [[ "$(realpath "$target_file")" == "$(realpath "$source_file")" ]]; then
      continue
    fi

    echo "  Updating references in: $target_file"

    # Choose the replacement strategy based on the file's content.
    if grep -q "source-crs/.*$file_name" "$target_file"; then
      # This file contains an incorrect 'source-crs' path. Fix it.
      sed -i -e "s|source-crs/[^[:space:]\`[]*${escaped_file_name}|source-crs/$replacement_path|g" "$target_file"
    else
      # This file contains a different incorrect full path. Fix it.
      # This regex finds a path-like string ending in the filename.
      replacement_path=${replacement_path#%source-crs/}
      sed -i -e "s|[^[:space:]\`[,]*${escaped_file_name}|${replacement_path}|g" "$target_file"
    fi
  done
done

echo "Script finished. Please review the changes made."
