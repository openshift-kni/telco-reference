#! /bin/bash

if sed --version 2>/dev/null | grep -q GNU; then
  sedi() { sed -i "$@"; }
else
  sedi() { sed -i '' "$@"; }
fi

trap cleanup EXIT

function cleanup() {
  rm -rf source_file rendered_file same_file
}

function read_dir() {
  local dir=$1
  local file

  for file in "$dir"/*; do
    if [ -d "$file" ]; then
      read_dir "$file"
    else
      echo "$file"
    fi
  done
}

function compare_cr {
  local rendered_dir=$1
  local source_dir=$2
  local exclusionfile=$3
  local status=0

  read_dir "$rendered_dir" |grep yaml  > rendered_file
  read_dir "$source_dir" |grep yaml  > source_file

  local source_cr rendered
  while IFS= read -r source_cr; do
    while IFS= read -r rendered; do
      if [ "${source_cr##*/}" = "${rendered##*/}" ]; then
        echo "$source_cr" >> same_file
      fi
    done < rendered_file
  done < source_file

  # Filter out files with a source-cr/reference match from the full list of potentiol source-crs/reference files
  while IFS= read -r file; do
    [[ ${file::1} != "#" ]] || continue # Skip any comment lines in the exclusionfile
    [[ -n ${file} ]] || continue # Skip empty lines
    sedi "/${file##*/}/d" source_file
    sedi "/${file##*/}/d" rendered_file
  done < <(cat same_file "$exclusionfile")

  if [[ -s source_file || -s rendered_file ]]; then
    [ -s source_file ] && printf "\n\nThe following files exist in source-crs only, but not found in reference:\n" && cat source_file
    [ -s rendered_file ] && printf "\nThe following files exist in reference only, but not found in source-crs:\n" && cat rendered_file
    status=1
  fi

  return $status
}

sync_cr() {
    local rendered_dir=$1
    local source_dir=$2
    local exclusionfile=$3
    local status=0

    local -a renderedFiles
    readarray -t renderedFiles < <(read_dir "$rendered_dir" | grep yaml)

    local -a sourceFiles
    readarray -t sourceFiles < <(read_dir "$source_dir" | grep yaml)

    local -a excludedFiles
    readarray -t excludedFiles < <(grep -v '^#' "$exclusionfile" | grep -v '^$')

    local source rendered excluded found
    for rendered in "${renderedFiles[@]}"; do
        found=0
        for source in "${sourceFiles[@]}"; do
            if [ "${source##*/}" = "${rendered##*/}" ]; then
                # Match found!
                found=1
                break
            fi
        done
        if [[ $found == 0 ]]; then
            source="$source_dir/${rendered##*/}"
        fi

        # Replace the CR with the rendered copy (minus the helm-rendered heading)
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

# Install-time MachineConfig CRs live only under telco-core/install/extra-manifests.
# kube-compare-reference holds validation templates; non-templated files must match install.
compare_install_extra_manifests() {
  local root fail=0
  root="$(git rev-parse --show-toplevel)"
  local install="${root}/telco-core/install/extra-manifests"
  local kubecmp="${root}/telco-core/configuration/reference-crs-kube-compare"
  local -a pairs=(
    "control-plane-load-kernel-modules.yaml:optional/other/control-plane-load-kernel-modules.yaml"
    "worker-load-kernel-modules.yaml:optional/other/worker-load-kernel-modules.yaml"
    "mount_namespace_config_master.yaml:optional/other/mount_namespace_config_master.yaml"
    "mount_namespace_config_worker.yaml:optional/other/mount_namespace_config_worker.yaml"
    "kdump-master.yaml:optional/other/kdump-master.yaml"
    "kdump-worker.yaml:optional/other/kdump-worker.yaml"
    "mc_rootless_pods_selinux.yaml:optional/networking/multus/tap_cni/mc_rootless_pods_selinux.yaml"
  )
  local pair inst ref refpath
  for pair in "${pairs[@]}"; do
    inst="${pair%%:*}"
    ref="${pair##*:}"
    refpath="${kubecmp}/${ref}"
    # kube-compare uses Go templates for some MCs; install holds rendered reference YAML.
    if grep -q '{{' "${refpath}"; then
      if ! grep -q 'validateBase64List' "${refpath}"; then
        echo "ERROR: expected validateBase64List templating in kube-compare ${ref}" >&2
        fail=1
      fi
      if ! grep -q 'version: 3.2.0' "${install}/${inst}"; then
        echo "ERROR: ${install}/${inst} must use ignition version 3.2.0" >&2
        fail=1
      fi
      if ! grep -q 'path: /etc/modules-load.d/kernel-load.conf' "${install}/${inst}"; then
        echo "ERROR: ${install}/${inst} must configure kernel-load.conf" >&2
        fail=1
      fi
      continue
    fi
    if ! diff -u "${install}/${inst}" "${refpath}"; then
      echo "ERROR: install/extra-manifests/${inst} differs from kube-compare ${ref}" >&2
      fail=1
    fi
  done
  local sctp="${install}/sctp_module_mc.yaml"
  if ! grep -q '{{' "${kubecmp}/optional/other/sctp_module_mc.yaml"; then
    echo "ERROR: expected templating in optional/other/sctp_module_mc.yaml" >&2
    fail=1
  fi
  if ! grep -q 'version: 3.2.0' "${sctp}"; then
    echo "ERROR: ${sctp} must use ignition version 3.2.0" >&2
    fail=1
  fi
  if ! grep -q 'source: data:,sctp' "${sctp}"; then
    echo "ERROR: ${sctp} must load sctp via data:,sctp" >&2
    fail=1
  fi
  if grep -q 'version: 2.2.0' "${sctp}" || grep -q 'filesystem: root' "${sctp}"; then
    echo "ERROR: ${sctp} must not use legacy ignition 2.2.0 / filesystem fields" >&2
    fail=1
  fi
  return $fail
}

# PolicyGenerator manifest paths must stay under telco-core/configuration/ (no ../).
# MCP CRs are duplicated here and must match install/extra-manifests.
compare_install_custom_manifests_mcp() {
  local root fail=0 f
  root="$(git rev-parse --show-toplevel)"
  local install="${root}/telco-core/install/extra-manifests"
  local custom="${root}/telco-core/configuration/reference-crs/custom-manifests"
  for f in mcp-worker-1.yaml mcp-worker-2.yaml mcp-worker-3.yaml; do
    if ! diff -u "${install}/${f}" "${custom}/${f}"; then
      echo "ERROR: install/extra-manifests/${f} differs from reference-crs/custom-manifests/${f}" >&2
      fail=1
    fi
  done
  return $fail
}

check_no_machineconfig_in_reference_crs() {
  local root fail=0 f
  root="$(git rev-parse --show-toplevel)"
  while IFS= read -r f; do
    echo "ERROR: MachineConfig must use install/extra-manifests, not reference-crs: ${f}" >&2
    fail=1
  done < <(grep -rl '^kind: MachineConfig$' "${root}/telco-core/configuration/reference-crs" 2>/dev/null || true)
  return $fail
}

run_extra_manifest_checks() {
  local status=0
  echo "Checking install/extra-manifests alignment with kube-compare-reference..."
  compare_install_extra_manifests || status=1
  echo "Checking install/extra-manifests MCPs match reference-crs/custom-manifests..."
  compare_install_custom_manifests_mcp || status=1
  echo "Checking reference-crs does not contain MachineConfig CRs..."
  check_no_machineconfig_in_reference_crs || status=1
  if [[ $status -eq 0 ]]; then
    echo "extra-manifest checks: OK"
  fi
  return $status
}

usage() {
    echo "$(basename "$0") [--sync] sourceDir renderDir ignoreFile"
    echo "$(basename "$0") --check-extra-manifests"
    echo
    echo "Compares the rendered reference-based CRs to the CRs in the compare directory,"
    echo "or validates install/extra-manifests vs kube-compare-reference."
}

DOSYNC=0
CHECK_EXTRA_MANIFESTS=0
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
        --check-extra-manifests)
            CHECK_EXTRA_MANIFESTS=1
            shift
            ;;
    esac
done

if [[ $CHECK_EXTRA_MANIFESTS == 1 ]]; then
    run_extra_manifest_checks
    exit $?
fi

SOURCEDIR=$1
if [[ ! -d $SOURCEDIR ]]; then
    echo "No such source directory $SOURCEDIR"
    usage
    exit 1
fi
RENDERDIR=$2
if [[ ! -d $RENDERDIR ]]; then
    echo "No such source directory $RENDERDIR"
    usage
    exit 1
fi
IGNORE=$3
if [[ ! -f $IGNORE ]]; then
    echo "No such ignorefile $IGNORE"
    usage
    exit 1
fi

if [[ $DOSYNC == 1 ]]; then
    sync_cr "$RENDERDIR" "$SOURCEDIR" "$IGNORE"
else
    compare_cr "$RENDERDIR" "$SOURCEDIR" "$IGNORE"
fi
