# Installation artifacts (RAN)

Reference install-time manifests for Telco RAN clusters using
[ClusterInstance](https://github.com/stolostron/siteconfig).

## Layout

- `extra-manifests/` — reference MachineConfig and related CRs applied at cluster install
- `custom-manifests/` — optional manifests (for example `enable-crun-*.yaml`) you add when needed
- `clusterinstance/` — example ClusterInstance CRs and kustomization with `configMapGenerator`

Reference MachineConfig CRs are rendered into `extra-manifests/` by
`telco-ran/configuration/extra-manifests-builder/`. At day-N, the Hub
**extra-manifests** policy keeps the cluster aligned with the install ConfigMap
(see `telco-hub/.../ztp-policies/extra-manifests-policy.yaml`).

PolicyGenerator examples under `telco-ran/configuration/argocd/` must not list
individual install-time MachineConfig files.

## ZTP site-generate container

The openshift-kni/cnf-features-deploy `resource-generator` Containerfile copies
reference install manifests into `$ZTP_HOME/extra-manifest`. After this layout
change, that COPY source must point at `telco-ran/install/extra-manifests/` while
keeping the container target path unchanged (follow-up PR in cnf-features-deploy).
