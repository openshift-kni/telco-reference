#!/usr/bin/env bash
# Keep kube-compare crun reference aligned with install-time source-crs copies.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
SRC="${ROOT}/telco-ran/configuration/source-crs/extra-manifest"
REF="${ROOT}/telco-ran/configuration/kube-compare-reference/machine-config/crun"
for f in enable-crun-master.yaml enable-crun-worker.yaml; do
  if ! diff -u "${SRC}/${f}" "${REF}/${f}"; then
    echo "ERROR: ${f} differs between source-crs/extra-manifest and kube-compare-reference" >&2
    exit 1
  fi
done
echo "check-ran-crun-extra-manifest-sync: OK"
