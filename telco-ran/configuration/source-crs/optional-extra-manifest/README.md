# optional-extra-manifest (source-crs)

`ContainerRuntimeConfig` manifests for **crun** (`enable-crun-*.yaml`) now live under
`../extra-manifest/` together with the other install-time reference manifests so
there is a single copy in git.

Policy examples under `argocd/example/` reference `extra-manifest/enable-crun-*.yaml`.

Optional IPsec and other **example-only** content remains under
`argocd/example/optional-extra-manifest/` (not this directory).
