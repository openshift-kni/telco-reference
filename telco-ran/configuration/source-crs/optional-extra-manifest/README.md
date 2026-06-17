# optional-extra-manifest (source-crs)

`ContainerRuntimeConfig` manifests for **crun** (`enable-crun-*.yaml`) live under
`../extra-manifest/` together with the other install-time reference manifests.

Apply them at **install** time via `ClusterInstance.spec.extraManifestsRefs`
(see `argocd/example/clusterinstance/` and `argocd/AdditionalManifests.md`).
Day-N alignment uses the Hub **extra-manifests** policy, not PolicyGenerator.

Optional IPsec and other **example-only** content remains under
`argocd/example/optional-extra-manifest/`.
