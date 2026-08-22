# Custom CRs

This directory holds CRs referenced by PolicyGenerator manifests under
`telco-core/configuration/`. Paths must stay under that directory tree because
the PolicyGenerator kustomize plugin rejects manifest paths outside it (no `../`).

## MachineConfigPool examples

Reference `MachineConfigPool` CRs (`mcp-worker-1.yaml` through `mcp-worker-3.yaml`)
are duplicated here for day-N policies (`core-finish`, `core-upgrade`,
`core-upgrade-finish`). The canonical install-time copies live under
`telco-core/install/extra-manifests/` and must remain identical; `compare.sh
--check-extra-manifests` enforces that.

Other custom content (for example `subscription-validator.yaml`) also belongs here.
