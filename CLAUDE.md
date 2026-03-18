# Claude Code Guidance for OpenShift Telco RDS Repository

## Repository Overview

This repository contains reference design specifications (RDS) for OpenShift telco deployments across three configurations:

- **telco-hub**: Hub cluster configuration (ACM, GitOps, TALM, storage)
- **telco-core**: Core/regional cluster configuration (networking, storage, scheduling)
- **telco-ran**: RAN/edge cluster configuration (DU profile, low-latency workloads)

Each configuration maintains two parallel directory structures:
- `reference-crs/` or `source-crs/`: Deployable manifests
- `reference-crs-kube-compare/` or `kube-compare-reference/`: Template versions with variables for validation

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
