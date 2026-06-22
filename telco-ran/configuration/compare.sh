#! /bin/bash

compare_install_extra_manifests() {
  local root fail=0 pair inst ref
  root="$(git rev-parse --show-toplevel)"
  local install="${root}/telco-ran/install/extra-manifests"
  local kubecmp="${root}/telco-ran/configuration/kube-compare-reference"
  local -a pairs=(
    "01-container-mount-ns-and-kubelet-conf-master.yaml:machine-config/kubelet-configuration-and-container-mount-hiding/01-container-mount-ns-and-kubelet-conf-master.yaml"
    "01-container-mount-ns-and-kubelet-conf-worker.yaml:machine-config/kubelet-configuration-and-container-mount-hiding/01-container-mount-ns-and-kubelet-conf-worker.yaml"
    "01-disk-encryption-pcr-rebind-master.yaml:machine-config/01-disk-encryption-pcr-rebind-master.yaml"
    "01-disk-encryption-pcr-rebind-worker.yaml:machine-config/01-disk-encryption-pcr-rebind-worker.yaml"
    "03-sctp-machine-config-master.yaml:machine-config/sctp/03-sctp-machine-config-master.yaml"
    "03-sctp-machine-config-worker.yaml:machine-config/sctp/03-sctp-machine-config-worker.yaml"
    "06-kdump-master.yaml:machine-config/kdump/06-kdump-master.yaml"
    "06-kdump-worker.yaml:machine-config/kdump/06-kdump-worker.yaml"
    "07-sriov-related-kernel-args-master.yaml:machine-config/sriov-related-kernel-arguments/07-sriov-related-kernel-args-master.yaml"
    "07-sriov-related-kernel-args-worker.yaml:machine-config/sriov-related-kernel-arguments/07-sriov-related-kernel-args-worker.yaml"
    "08-set-rcu-normal-master.yaml:machine-config/set-rcu-normal/08-set-rcu-normal-master.yaml"
    "08-set-rcu-normal-worker.yaml:machine-config/set-rcu-normal/08-set-rcu-normal-worker.yaml"
    "09-openshift-marketplace-ns.yaml:cluster-tuning/09-openshift-marketplace-ns.yaml"
    "10-rename-gnrd-interfaces-master.yaml:machine-config/rename-gnrd-interfaces/10-rename-gnrd-interfaces-master.yaml"
    "10-rename-gnrd-interfaces-worker.yaml:machine-config/rename-gnrd-interfaces/10-rename-gnrd-interfaces-worker.yaml"
    "99-sync-time-once-master.yaml:machine-config/one-shot-time-sync/99-sync-time-once-master.yaml"
    "99-sync-time-once-worker.yaml:machine-config/one-shot-time-sync/99-sync-time-once-worker.yaml"
  )
  for pair in "${pairs[@]}"; do
    inst="${pair%%:*}"
    ref="${pair##*:}"
    if ! diff -u "${install}/${inst}" "${kubecmp}/${ref}"; then
      echo "ERROR: install/extra-manifests/${inst} differs from kube-compare ${ref}" >&2
      fail=1
    fi
  done
  return $fail
}

compare_install_custom_manifests_crun() {
  local root fail=0 f
  root="$(git rev-parse --show-toplevel)"
  local custom="${root}/telco-ran/install/custom-manifests"
  local kubecmp="${root}/telco-ran/configuration/kube-compare-reference/machine-config/crun"
  for f in enable-crun-master.yaml enable-crun-worker.yaml; do
    if ! diff -u "${custom}/${f}" "${kubecmp}/${f}"; then
      echo "ERROR: install/custom-manifests/${f} differs from kube-compare machine-config/crun/${f}" >&2
      fail=1
    fi
  done
  return $fail
}

check_no_machineconfig_in_source_crs() {
  local root fail=0 f
  root="$(git rev-parse --show-toplevel)"
  while IFS= read -r f; do
    echo "ERROR: MachineConfig must use install/extra-manifests, not source-crs: ${f}" >&2
    fail=1
  done < <(grep -rl '^kind: MachineConfig$' "${root}/telco-ran/configuration/source-crs" 2>/dev/null || true)
  return $fail
}

run_extra_manifest_checks() {
  local status=0
  echo "Checking install/extra-manifests alignment with kube-compare-reference..."
  compare_install_extra_manifests || status=1
  echo "Checking install/custom-manifests enable-crun vs kube-compare crun..."
  compare_install_custom_manifests_crun || status=1
  echo "Checking source-crs does not contain MachineConfig CRs..."
  check_no_machineconfig_in_source_crs || status=1
  if [[ $status -eq 0 ]]; then
    echo "extra-manifest checks: OK"
  fi
  return $status
}

if [[ "${1:-}" == "--check-extra-manifests" ]]; then
  run_extra_manifest_checks
  exit $?
fi

echo "Usage: $(basename "$0") --check-extra-manifests" >&2
exit 1
