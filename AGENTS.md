# Claude Code Guidance for OpenShift Telco RDS Repository

## Repository Overview

This repository contains reference design specifications (RDS) for OpenShift telco deployments across three configurations:

- **telco-hub**: Hub cluster configuration (ACM, GitOps, TALM, storage)
- **telco-core**: Core/regional cluster configuration (networking, storage, scheduling)
- **telco-ran**: RAN/edge cluster configuration (DU profile, low-latency workloads)

## Common directory structure

The three references share a common `configuration/` layout:

- `reference-crs/`: Deployable manifests
- `reference-crs-kube-compare/`: Template versions with variables for validation
- `acmpolicygenerator/`: ACM PolicyGenerator CRs
- `argocd/deployment/` and `argocd/example/`: GitOps app-of-apps/RBAC and
  user-facing examples (overlays, cluster-install examples)
- `install/clusterinstance/`: managed-cluster install manifests

Directories were aligned to this common layout without disturbing the
extracted container payloads or the ztp-site-generate inputs: wherever content
was relocated, a backwards-compatibility **symlink** was left at the previous
path (this mirrors the pre-existing symlinks under
`telco-ran/configuration/reference-crs/`). Manifests, scripts and external
consumers that still reference the old paths resolve transparently through
these symlinks, so shipped content is byte-for-byte unchanged.

Documented, reference-specific exceptions (no cross-reference analog):

- **telco-ran** keeps `kube-compare-reference/` (its templates are not renamed
  to `reference-crs-kube-compare/`), and `source-crs/` remains as a
  compatibility symlink to `reference-crs/` for the ztp-site-generate pipeline.
  `policygentemplates/` and `install/extra-manifests-builder/` are RAN-only.
- **telco-core** keeps `ns.yaml` and the generated `schema.openapi` at
  `configuration/` (wired into the shared schema tooling).
- **telco-hub** `install/` installs the *hub* cluster (`mirror-registry/`,
  `openshift/`) — a different function from the managed-cluster
  `install/clusterinstance/` — and has no `template-values/`.

## Version Updates

For detailed instructions on updating this repository for a new OpenShift release, see [VERSION_UPDATE_GUIDE.md](VERSION_UPDATE_GUIDE.md).

The guide covers:
- Operator subscription updates across all three references
- Policy generator version-specific naming conventions
- ClusterInstance and AgentServiceConfig updates
- Mirror registry configuration
- Metadata documentation updates
- Version numbering patterns for different operators
- Common pitfalls and testing procedures

## Branch Strategy

- Main branch represents the **current development** release
- Each major release gets its own reference configurations
- Version numbers throughout the repository should be consistent
- The repository name/branch determines the target OpenShift version

## Contact & Contributions

For questions about version updates or policy generators:
- Check the telco-core/configuration/README.md for upgrade policy details
- Check the telco-ran/configuration/argocd/README.md for GitOps/ZTP requirements
- ACM version compatibility matrix is documented in telco-ran README
