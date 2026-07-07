# Reference configuration

## Structure
This directory contains the RAN reference configuration:
 - `acmpolicygenerator/` contains PolicyGenerator CRs (`ran-*.yaml`) that define how CRs from `source-crs/` are patched with use-case specific values and grouped into ordered policies. Group policies use hub-side templating with ConfigMaps in `template-values/` for hardware-type and zone-specific values. [policy-generator-plugin](https://github.com/stolostron/policy-generator-plugin) constructs Advanced Cluster Management Policies.
 - `policygentemplates/` contains deprecated PolicyGenTemplate (PGT) equivalents of the hub-side-templated group policies, provided for reference only.
 - `source-crs/` contains the CRs which form the foundation of the RAN reference configuration.
 - `template-values/` contains ConfigMaps used by hub-side templating to inject hardware-type, zone, and site-specific values into policies.
 - `extra-manifests-builder/` is used to create the extra-manifests in `source-crs/extra-manifest/` directory.
 - `kube-compare-reference/` contains the RAN reference configuration CRs with templating required for the kube-compare tool.
 - `argocd/` contains documentation and additional examples:
   - `argocd/example/clusterinstance/` has ClusterInstance examples for SNO, 3-node, and standard clusters.
   - `argocd/example/image-based-upgrades/` has examples pertaining to image based upgrades.
   - `argocd/example/optional-extra-manifest/` has optional extra-manifest examples (e.g. IPsec).

## Deprecation notice

The previous `argocd/example/policygentemplates/` and `argocd/example/acmpolicygenerator/` directories have been moved to this level as `policygentemplates/` and `acmpolicygenerator/`. Non-templated group policy examples have been removed — only hub-side-templated policies are provided. PolicyGenTemplate (PGT) CRs in `policygentemplates/` are deprecated; use the PolicyGenerator CRs in `acmpolicygenerator/` instead.
