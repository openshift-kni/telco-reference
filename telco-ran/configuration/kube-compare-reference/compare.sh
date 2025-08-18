#! /bin/bash

TEMPDIR=$(mktemp -d)

trap cleanup EXIT

cleanup() {
  if [[ -z $COMPARE_NO_CLEANUP ]]; then
    echo "Cleaning up temporary directory $TEMPDIR (To prevent auto-cleanup, set COMPARE_NO_CLEANUP=1)"
    rm -rf "$TEMPDIR"
  else
    echo "Temporary directory not deleted: $TEMPDIR"
  fi
}

check_requirement() {
  local cmd=$1
  local installer=$2
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd isn't installed; please download and install it:"
    echo "  $installer"
    return 1
  fi
  return 0
}

check_requirements() {
  local missing=0
  check_requirement helm-convert \
    "go install github.com/openshift/kube-compare/addon-tools/helm-convert@latest" ||
    missing=1
  check_requirement helm \
    "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash" ||
    missing=1
  return $missing
}

helmconvert() {
  local metadata=$1
  local values=$2
  local rendered_dir=$3
  local chart_dir="$TEMPDIR/chart"
  echo "Converting reference files from $metadata with values $values to helm chart in $chart_dir"
  helm-convert -r "$metadata" -n "$chart_dir" -v "$values" || return 1
  echo "Rendering helm chart into $rendered_dir"
  helm template rendered "$chart_dir" --output-dir "$rendered_dir" || return 1
}

filterout() {
  local source_file=$1
  local rendered_file=$2
  local filter_file=$3
  local reason=$4

  while IFS= read -r file; do
    [[ ${file::1} != "#" ]] || continue # Skip any comment lines in the exclusionfile
    [[ -n ${file} ]] || continue        # Skip empty lines
    local fname=${file##*/}
    echo "Filtering out $reason $fname ($file)"
    sed -i "/$fname/d" "$source_file"
    sed -i "/$fname/d" "$rendered_file"
  done < <(cat "$filter_file")
}

SEPARATOR='**********************************************************************************'
compare_cr() {
  local rendered_dir=$1
  local source_dir=$2
  local exclusionfile=$3
  local status=0
  local source_file="$TEMPDIR/source_file"
  local rendered_file="$TEMPDIR/rendered_file"
  local same_file="$TEMPDIR/same_file"

  local DIFF=${DIFF:-colordiff}
  if ! command -v "$DIFF" >/dev/null; then
    echo "Warning: Requested diff tool '$DIFF' is not found; falling back to plain old 'diff'"
    DIFF="diff"
  fi

  find "$rendered_dir" -name '*.yaml' >"$rendered_file"
  find "$source_dir" -name '*.yaml' >"$source_file"

  local source_cr rendered
  while IFS= read -r source_cr; do
    while IFS= read -r rendered; do
      if [ "${source_cr##*/}" = "${rendered##*/}" ]; then
        # helm adds a yaml doc header (---) and a leading comment to every source_cr file; so remove those lines
        tail -n +3 "$rendered" >"$rendered.fixed"
        mv "$rendered.fixed" "$rendered"

        # Check the differences
        if ! "$DIFF" -u "$source_cr" "$rendered"; then
          status=$((status || 1))
          printf "\n\n%s\n\n" "$SEPARATOR"
        fi
        # cleanup
        echo "$source_cr" >>"$same_file"
      fi
    done <"$rendered_file"
  done <"$source_file"

  # Filter out files with a source-cr/reference match from the full list of potential source-crs/reference files
  filterout "$source_file" "$rendered_file" "$same_file" "found"
  filterout "$source_file" "$rendered_file" "$exclusionfile" "excluded"

  echo "$SEPARATOR"
  if [[ -s "$source_file" || -s "$rendered_file" ]]; then
    [ -s "$source_file" ] && printf "\nThe following files exist in source-crs only, but not found in reference:\n" && cat "$source_file"
    [ -s "$rendered_file" ] && printf "\nThe following files exist in reference only, but not found in source-crs:\n" && cat "$rendered_file"
    status=1
  else
    echo " ✓ All cluster-compare reference files correlate 1:1 with $source_dir"
  fi
  echo "$SEPARATOR"

  return $status
}

sync_cr() {
  local rendered_dir=$1
  local source_dir=$2
  local exclusionfile=$3
  local status=0

  local -a renderedFiles
  readarray -t renderedFiles < <(find "$rendered_dir" -name '*.yaml')

  local -a sourceFiles
  readarray -t sourceFiles < <(find "$source_dir" -name '*.yaml')

  local -a excludedFiles
  readarray -t excludedFiles < <(grep -v '^#' "$exclusionfile" | grep -v '^$')

  local source rendered excluded found
  for rendered in "${renderedFiles[@]}"; do
    local rendered_base=${rendered#*/templates/}
    found=0
    for excluded in "${excludedFiles[@]}"; do
      if [ "${rendered##*/}" = "${excluded##*/}" ]; then
        # Match found!
        found=1
        break
      fi
    done
    if [[ $found == 1 ]]; then
      # Do NOT use rendered file (it is excluded!)
      echo "sync: Excluding rendered file $rendered_base"
      continue
    fi

    found=0
    for source in "${sourceFiles[@]}"; do
      if [ "${source##*/}" = "${rendered##*/}" ]; then
        # Match found!
        found=1
        break
      fi
    done
    if [[ $found == 0 ]]; then
      rendered_base=${rendered_base#optional/}
      rendered_base=${rendered_base#required/}
      source="$source_dir/${rendered_base}"
    fi

    # Replace the CR with the rendered copy (minus the helm-rendered heading)
    mkdir -p "$(dirname "$source")"
    tail -n +3 "$rendered" >"$source"
    git add "$source"
  done

  for source in "${sourceFiles[@]}"; do
    found=0
    for rendered in "${renderedFiles[@]}"; do
      if [ "${source##*/}" = "${rendered##*/}" ]; then
        # Match found!
        found=1
        break
      fi
    done
    for excluded in "${excludedFiles[@]}"; do
      if [ "${source##*/}" = "${excluded##*/}" ]; then
        # Match found!
        found=1
        break
      fi
    done
    if [[ $found == 0 ]]; then
      git rm -f "$source"
    fi
  done

  git diff --cached --stat --exit-code
}

usage() {
  echo "$(basename "$0") [--sync] sourceDir metadata.yaml default_value.yaml"
  echo
  echo "Compares the rendered reference-based CRs to the CRs in the compare directory"
}

DOSYNC=0
for arg in "$@"; do
  case "$arg" in
  -h | --help)
    usage
    exit 0
    ;;
  --sync)
    DOSYNC=1
    shift
    ;;
  esac
done

SOURCEDIR=$1
if [[ ! -d $SOURCEDIR ]]; then
  echo "No such source directory $SOURCEDIR"
  usage
  exit 1
fi
shift

METADATA=$1
if [[ ! -f $METADATA ]]; then
  echo "No such metadata.yaml $METADATA"
  usage
  exit 1
fi
shift

VALUES=$1
if [[ ! -f $VALUES ]]; then
  echo "No such default_value.yaml $VALUES"
  usage
  exit 1
fi

check_requirements || exit 1

RENDERDIR=$TEMPDIR/rendered
mkdir -p "$RENDERDIR"
helmconvert "$METADATA" "$VALUES" "$RENDERDIR" || exit 1

if [[ $DOSYNC == 1 ]]; then
  sync_cr "$RENDERDIR" "$SOURCEDIR" compare_ignore
else
  compare_cr "$RENDERDIR" "$SOURCEDIR" compare_ignore
fi
