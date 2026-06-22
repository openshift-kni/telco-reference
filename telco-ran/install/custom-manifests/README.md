# Optional RAN install manifests

Place optional install-time manifests here and reference an additional ConfigMap
from `ClusterInstance.spec.extraManifestsRefs`.

`enable-crun-master.yaml` and `enable-crun-worker.yaml` set the default container
runtime to crun. Include them in your install ConfigMap when required; do not
list them in PolicyGenerator CRs. kube-compare-reference retains matching CRs under
`machine-config/crun/` for cluster validation only.
