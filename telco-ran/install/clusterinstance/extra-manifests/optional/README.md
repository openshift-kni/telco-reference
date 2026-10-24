# Optional RAN install manifests

These manifests are opt-in and are not included in the default install
ConfigMap. To use them, add the selected files to a separate ConfigMap and
reference that ConfigMap from `ClusterInstance.spec.extraManifestsRefs`. Do not
list optional install-time manifests in PolicyGenerator CRs.
