# Custom CRs

This directory is a placeholder for additional custom CRs which are
outside the scope of the reference CRs (for example `subscription-validator.yaml`).

## MachineConfigPool examples

Reference `MachineConfigPool` CRs (`mcp-worker-1.yaml` through `mcp-worker-3.yaml`)
live under `telco-core/install/extra-manifests/` together with the other
install-time reference manifests. Policy generators under `../` reference those
files directly so there is a single copy in git.
