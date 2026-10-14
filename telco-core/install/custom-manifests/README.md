# Custom installation manifests

Place additional manifests you want applied at cluster install time here and
include a `ConfigMap` (for example `custom-manifests-configmap`) in your
`ClusterInstance.spec.extraManifestsRefs`.

The reference **MachineConfigPool** examples (`mcp-worker-1.yaml` through
`mcp-worker-3.yaml`) now live under `../extra-manifests/` together with the
other reference `MachineConfig` CRs so there is a single copy in git.
