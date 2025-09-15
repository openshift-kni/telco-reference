#!/bin/bash

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

kubectl cluster-compare \
    --reference-dir="${SCRIPTDIR}" \
    --comparison-overrides-file="${SCRIPTDIR}/comparison-overrides.yaml" \
    --default-value-file="${SCRIPTDIR}/default_value.yaml" \
    --ignore-file="${SCRIPTDIR}/compare_ignore" \
    "$@" 