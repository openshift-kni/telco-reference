#!/usr/bin/env bash
# Ensure telco-core install-time MachineConfig YAML matches kube-compare reference
# content (single source of truth: telco-core/install/extra-manifests).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
INSTALL="${ROOT}/telco-core/install/extra-manifests"
KUBECMP="${ROOT}/telco-core/configuration/reference-crs-kube-compare"

# basename_in_install:relative_path_under_kube-compare
PAIRS=(
  "control-plane-load-kernel-modules.yaml:optional/other/control-plane-load-kernel-modules.yaml"
  "worker-load-kernel-modules.yaml:optional/other/worker-load-kernel-modules.yaml"
  "mount_namespace_config_master.yaml:optional/other/mount_namespace_config_master.yaml"
  "mount_namespace_config_worker.yaml:optional/other/mount_namespace_config_worker.yaml"
  "kdump-master.yaml:optional/other/kdump-master.yaml"
  "kdump-worker.yaml:optional/other/kdump-worker.yaml"
  "mc_rootless_pods_selinux.yaml:optional/networking/multus/tap_cni/mc_rootless_pods_selinux.yaml"
)

fail=0
for pair in "${PAIRS[@]}"; do
  inst="${pair%%:*}"
  ref="${pair##*:}"
  if ! diff -u "${INSTALL}/${inst}" "${KUBECMP}/${ref}"; then
    echo "ERROR: ${inst} differs from kube-compare ${ref}" >&2
    fail=1
  fi
done

# sctp_module_mc is templated in kube-compare; validate install matches expected content.
SCTP="${INSTALL}/sctp_module_mc.yaml"
if ! grep -q '{{' "${KUBECMP}/optional/other/sctp_module_mc.yaml"; then
  echo "ERROR: expected templating in optional/other/sctp_module_mc.yaml" >&2
  fail=1
fi
if ! grep -q 'version: 3.2.0' "${SCTP}"; then
  echo "ERROR: ${SCTP} must use ignition version 3.2.0" >&2
  fail=1
fi
if ! grep -q 'source: data:,sctp' "${SCTP}"; then
  echo "ERROR: ${SCTP} must load sctp via data:,sctp" >&2
  fail=1
fi
if grep -q 'version: 2.2.0' "${SCTP}" || grep -q 'filesystem: root' "${SCTP}"; then
  echo "ERROR: ${SCTP} must not use legacy ignition 2.2.0 / filesystem fields" >&2
  fail=1
fi

if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi
echo "check-core-install-extra-manifest-sync: OK"
