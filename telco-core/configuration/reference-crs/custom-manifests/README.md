# Custom CRs

This directory is a placeholder for additional custom CRs which are
outside the scope of the reference CRs.

Paths must stay under the `telco-core/configuration/` directory tree because
the PolicyGenerator kustomize plugin rejects manifest paths outside it (no `../`).

## MachineConfigPool examples

Reference `MachineConfigPool` CRs (`mcp-worker-1.yaml` through `mcp-worker-3.yaml`)
are duplicated here for day-N policies (`core-finish`, `core-upgrade`,
`core-upgrade-finish`). The canonical install-time copies live under
`telco-core/install/extra-manifests/` and must remain identical; `compare.sh
--check-extra-manifests` enforces that.

Other custom content (for example `subscription-validator.yaml`) also belongs here.
