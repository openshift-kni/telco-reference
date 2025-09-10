#!/bin/bash

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

DIFF=${DIFF:-colordiff}
check_requirements() {
  local missing=0

  check_requirement helm-convert \
    "go install github.com/openshift/kube-compare/addon-tools/helm-convert@latest" ||
    missing=1

  check_requirement helm \
    "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash" ||
    missing=1

  if [[ $DOSYNC != 1 ]]; then
    if ! command -v "$DIFF" >/dev/null; then
      echo "Warning: Requested diff tool '$DIFF' is not found; falling back to plain old 'diff'"
      DIFF="diff"
    fi
  fi

  return $missing
}

copy_unique() {
  local aprefix=$1
  local a=$2
  local bprefix=$3
  local b=$4
  local dest=$5
  if diff -s "$a" "$b" >/dev/null; then
    # Files match!  Copy verbatim
    mkdir -p "$(dirname "$dest")"
    cp "$a" "$dest"
    echo "  common: $dest"
  else
    local base=${dest%/*}
    local leaf=${dest##*/}
    mkdir -p "$base/$aprefix"
    cp "$a" "$base/$aprefix/$leaf"
    mkdir -p "$base/$bprefix"
    cp "$b" "$base/$bprefix/$leaf"
    echo "  bifurcated: $base/{$aprefix|$bprefix}/$leaf"
  fi
}

helm_per_arch() {
  local chart_dir=$1
  local rendered_dir=$2
  local archdir=$3
  local errors=0
  local arch_list=()
  for archvalues in "$archdir"/*.yaml; do
    local arch=${archvalues##*/}
    arch=${arch%.*}
    arch_list+=("$arch")
    local rendered_arch="$rendered_dir.$arch"
    echo "Rendering helm chart for $archvalues into $rendered_arch"
    if ! helm template rendered "$chart_dir" --output-dir "$rendered_arch" --values "$archvalues"; then
      errors=$((errors + 1))
      continue
    fi
  done
  local first=${arch_list[0]}
  local rendered_first="$rendered_dir.$first"
  local first_files
  readarray -t first_files < <(find "$rendered_first" -type f)
  for arch in "${arch_list[@]}"; do
    if [[ $arch == "$first" ]]; then
      continue
    fi
    local rendered_arch="$rendered_dir.$arch"
    local arch_files
    readarray -t arch_files < <(find "$rendered_arch" -type f)
    echo "Comparing $arch to $first to sort out common and arch-specific files"
    for first_file in "${first_files[@]}"; do
      local relative_file=${first_file#"$rendered_first"/}
      local rendered_file="$rendered_dir/$relative_file"
      for arch_file in "${arch_files[@]}"; do
        if [[ $arch_file != "$rendered_arch/$relative_file" ]]; then
          continue
        fi
        copy_unique "$first" "$first_file" "$arch" "$arch_file" "$rendered_file"
      done
    done
  done
  return $errors
}

helmconvert() {
  local metadata=$1
  local values=$2
  local rendered_dir=$3
  local archdir=${4%/}
  local chart_dir="$TEMPDIR/chart"
  echo "Converting reference files from $metadata with values $values to helm chart in $chart_dir"
  helm-convert -r "$metadata" -n "$chart_dir" -v "$values" || return 1
  if [[ -n $archdir && -d $archdir ]]; then
    helm_per_arch "$chart_dir" "$rendered_dir" "$archdir" || return 1
  else
    echo "Rendering helm chart into $rendered_dir"
    helm template rendered "$chart_dir" --output-dir "$rendered_dir" || return 1
  fi
}

SEPARATOR='**********************************************************************************'
compare_cr() {
  local rendered_dir=$1
  local source_dir=$2
  local exclusionfile=$3

  # Used to tally descrptencies in compare mode
  local -a missing_rendered
  local -a missing_sources
  local -a diff_files

  local -a renderedFiles
  readarray -t renderedFiles < <(find "$rendered_dir" -name '*.yaml')

  local -a sourceFiles
  readarray -t sourceFiles < <(find "$source_dir" -name '*.yaml')
  local remainingSources=("${sourceFiles[@]}")

  local -a excludedFiles
  readarray -t excludedFiles < <(grep -v '^#' "$exclusionfile" | grep -v '^$')

  # Sync direction 1: Compare all rendered files to all source files.
  local source rendered excluded found
  for rendered in "${renderedFiles[@]}"; do
    local rendered_base=${rendered#*/templates/}
    local found=0
    for excluded in "${excludedFiles[@]}"; do
      if [ "${rendered##*/}" = "${excluded##*/}" ]; then
        # Match found!
        found=1
        break
      fi
    done
    if [[ $found == 1 ]]; then
      # Do NOT use rendered file (it is excluded!)
      echo "compare: Excluding rendered file $rendered_base"
      continue
    fi

    # helm adds a yaml doc header (---) and a leading comment to every source_cr file; so remove those lines
    tail -n +3 "$rendered" >"$rendered.fixed"
    mv "$rendered.fixed" "$rendered"

    found=0
    for source in "${sourceFiles[@]}"; do
      local source_base=${source#"$source_dir"/}
      if [[ "$source_base" == "$rendered_base" ]]; then
        echo "compare: exact match: $source_base"
        found=1
        break
      fi
    done
    if [[ $found == 0 ]]; then
      for source in "${sourceFiles[@]}"; do
        if [ "${source##*/}" = "${rendered##*/}" ]; then
          # Match found!
          echo "compare: fuzzy match $source_base ($rendered_base)"
          found=1
          break
        fi
      done
    fi

    if [[ $found == 1 ]]; then
      local nextRemainingSources=()
      for remainder in "${remainingSources[@]}"; do
        # Copy everything except this just-matched source file into the remainder list
        if [[ $remainder != "$source" ]]; then
          nextRemainingSources+=("$remainder")
        fi
      done
      remainingSources=("${nextRemainingSources[@]}")
    else
      echo "compare: missing source for $rendered_base"
      missing_sources+=("$rendered_base")
    fi

    if [[ $DOSYNC == 1 ]]; then
      # Replace the CR with the rendered copy (minus the helm-rendered heading)
      if [[ $found == 0 ]]; then
        echo "sync: creating missing $source_base"
        source="$source_dir/${rendered_base}"
      else
        echo "sync: synchronizing $source_base"
      fi
      mkdir -p "$(dirname "$source")"
      cp "$rendered" "$source"
      git add "$source"
    else
      if [[ $found == 1 ]]; then
        # Check for differences
        if ! "$DIFF" -u "$source" "$rendered"; then
          printf "\n\n%s\n\n" "$SEPARATOR"
          diff_files+=("$source_base")
        else
          echo "compare: no diff found for $source_base"
        fi
      fi
    fi
  done

  # Sync direction 2: Look for any source files not covered already by rendered files
  for source in "${remainingSources[@]}"; do
    source_base=${source#"$source_dir"/}
    found=0
    for excluded in "${excludedFiles[@]}"; do
      if [ "${source##*/}" = "${excluded##*/}" ]; then
        # Match found!
        echo "compare: Excluding non-rendered source file $source_base"
        found=1
        break
      fi
    done
    if [[ $found == 0 ]]; then
      if [[ $DOSYNC == 1 ]]; then
        echo "sync: removing $source"
        git rm -f "$source"
      else
        echo "compare: Missing rendered file for $source_base"
        missing_rendered+=("$source")
      fi
    fi
  done

  printf "\n%s\n" "$SEPARATOR"
  echo "Summary:"
  local status=0
  if [[ $DOSYNC == 1 ]]; then
    git diff --cached --stat --exit-code
    status=$?
  else
    echo "  Rendered:  ${#renderedFiles[@]}"
    echo "  Sources:   ${#sourceFiles[@]}"
    echo "  Diffs:     ${#diff_files[@]}"
    echo "  Unmatched sources:  ${#missing_sources[@]}"
    for file in "${missing_sources[@]}"; do
      echo "    - $file"
    done
    echo "  Unmatched rendered: ${#missing_rendered[@]}"
    for file in "${missing_rendered[@]}"; do
      echo "    - $file"
    done
    if [[ $((${#diff_files[@]} + ${#missing_sources[@]} + ${#missing_rendered[@]})) -gt 0 ]]; then
      status=1
    fi
  fi
  printf "%s\n\n" "$SEPARATOR"
  return $status
}

usage() {
  echo "$(basename "$0") [--sync] sourceDir metadata.yaml default_value.yaml compare_ignore arch_dir"
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
shift

COMPARE_IGNORE=$1
if [[ ! -f $COMPARE_IGNORE ]]; then
  echo "No such compare_ignore $COMPARE_IGNORE"
  usage
  exit 1
fi
shift

ARCHDIR=$1
if [[ -n $ARCHDIR && ! -d $ARCHDIR ]]; then
  echo "No such arch-dir $ARCHDIR"
  usage
  exit 1
fi
shift

check_requirements || exit 1

RENDERDIR=$TEMPDIR/rendered
mkdir -p "$RENDERDIR"
helmconvert "$METADATA" "$VALUES" "$RENDERDIR" "$ARCHDIR" || exit 1

compare_cr "$RENDERDIR" "$SOURCEDIR" "$COMPARE_IGNORE"
