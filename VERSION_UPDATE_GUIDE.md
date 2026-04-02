# OpenShift Version Update Guide

This guide provides step-by-step instructions for updating the telco RDS repository for a new OpenShift release.

## Overview

When updating this repository for a new OpenShift version (e.g., 4.22 → 4.23), follow this comprehensive checklist. Each section below details specific files and changes required across the three reference configurations (telco-hub, telco-core, telco-ran).

## Update Checklist

### 1. Operator Subscriptions

Update operator channel versions in subscription files across all three configurations:

**Standard operators** (align with OpenShift version):
- Update to match OpenShift version
  - Channel format: `4.X` (e.g., `4.22` → `4.23`)
  - Files: `telco-core/configuration/reference-crs/required/scheduling/NROPSubscription.yaml` and kube-compare variant

**Operators with custom numbering**:
- **Cluster Logging Operator**: Update to latest stable
  - Channel format: `stable-X.Y` (e.g., `stable-6.4` → `stable-6.5`)

- **GitOps Operator**: Update to latest compatible version
  - Channel format: `gitops-X.Y` (e.g., `gitops-1.19` → `gitops-1.20`)
  - Files: `telco-hub/configuration/reference-crs/required/gitops/gitopsSubscription.yaml`
  - Also: `telco-ran/configuration/argocd/deployment/openshift-gitops-operator.yaml`

- **ACM (Advanced Cluster Management)**: Update to latest
  - ACM version is OCP version minus 5. OCP version `4.22` → ACM version `2.17`
  - Channel format: `release-X.Y` (e.g., `release-2.17` → `release-2.18`)
  - Multi Cluster Engine (MCE) is delivered with ACM. The MCE version is ACM minus 5: ACM version `2.17` → MCE version `2.12`
  - Also update ACM and MCE versions in mirror registry config (see below)

- **ODF (OpenShift Data Foundation)**: **Special case!**
  - ODF releases 2-4 weeks **after** OpenShift GA
  - Ask if the ODF version should align with OCP or use the prior, N-1, version
  - Initially update to N-1 version (e.g., for OCP 4.23, use ODF `stable-4.22`)
  - Update to matching version after ODF release
  - Channel format: `stable-X.Y`
  - Files: Multiple locations in telco-hub and telco-core
  - **Also update ALL ODF sub-operators** in mirror registry config (see below)

**Remember**: Update both `reference-crs/` AND `reference-crs-kube-compare/` (or `source-crs/` and `kube-compare-reference/`) versions!

### 2. Policy Generator Files

Policy generators define ACM policies and must be updated with version-specific names and selectors. Each reference has different policy generator files to update.

**What to change**:
The policy names in each PolicyGenerator have a version suffix which MUST match the OpenShift version. For example with OpenShift version 4.23 the policy name is `example-policy-23`.
```yaml
# PolicyGenerator metadata name
metadata:
  name: core-baseline-19  # → core-baseline-23
  # OR
  name: core-overlay-22   # → core-overlay-23

# Version selector
placement:
  clusterSelectors:
    version: "4.22"  # → "4.23"

# Policy names (use new version number)
policies:
  - name: core-cluster-config-4.19  # → core-cluster-config-4.23
  - name: core-operator-subs-4.22   # → core-operator-subs-4.23

# Operator index images
patches:
  - spec:
      image: registry.redhat.io/redhat/redhat-operator-index:v4.22  # → v4.23
```

- Update PolicyGenerator patches for Subscription `channel: <value>`
- Update PolicyGenerator patches for pullspec images with versioned tags
- Update PolicyGenerator placement specifications which use version
- Policy generator policy names MUST use version numbers which match the OpenShift version number (e.g., `core-cluster-config-4.23`)

### 3. Image references
The reference configuration includes image pullspecs in several places which use version specific tags for the image. These must be updated. These pullspecs may be in the reference-crs or in PolicyGenerator patches. Common places where image tags are used include:
- CatalogSource images -- Update both the reference-cr and the PolicyGenerator overlay patch to align with the OpenShift version
- Numa Resources Operator (NROP) -- Update image spec in the Scheduler (sched.yaml) and PolicyGenerator overlay patch to align with the OpenShift version
- Upgrade policy -- Update the version and image pull spec in the PolicyGenerator overlay patch to align with the OpenShift version
- The telco-hub reference includes a plugins Policy CR with image pullspec references which must be updated to the correct versions. The ztp-site-generate image aligns with OpenShift. The multicluster-operator image aligns with MCE.

### 4. ACM AgentServiceConfig

Add new OpenShift version osImages entries and remove the oldest version to maintain only 3 versions:

**Files**:
- `telco-hub/configuration/reference-crs/required/acm/acmAgentServiceConfig.yaml`
- `telco-hub/configuration/reference-crs-kube-compare/default_value.yaml`
- `telco-hub/configuration/example-overlays-config/acm/options-agentserviceconfig-patch.yaml`

**Important**: Keep only the **3 most recent versions** (current + 2 previous) in osImages.

**For 4.22 → 4.23 update**:
1. Remove 4.20 entries
2. Add 4.23 entries
3. Result: Keep only 4.21, 4.22, 4.23

**Add new entry**:
```yaml
osImages:
  # ... existing 4.21, 4.22 entries ...
  - cpuArchitecture: "x86_64"
    openshiftVersion: "4.23"
    rootFSUrl: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.23/latest/rhcos-live-rootfs.x86_64.img
    url: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.23/latest/rhcos-live-iso.x86_64.iso
    version: "9.6.YYYYMMDD-0"  # Replace YYYYMMDD with the RHCOS build date from the image metadata
```

**To find the RHCOS version**: Download the `.iso.sha256` file from the same RHCOS directory and extract the version from the filename or check the release metadata file (`commitmeta.json`) in the RHCOS release directory.

**Note**: The kube-compare variant uses templating and doesn't require manual entry removal - it renders from the actual config.

### 5. Mirror Registry Configuration

**File**: `telco-hub/install/mirror-registry/imageset-config.yaml`

The versions of each component in the mirror configuration must be updated. These versions must align with the changes made in corresponding Subscription updates.
- Mirroring versions MUST match the Subscription versions for each operator
- The additional images MUST include the images specified in the Hub reference plugins Policy

### 6. Installation Examples (ClusterInstance)

Find all ClusterInstance CRs (`kind: ClusterInstance`) and update clusterImageSetNameRef to align with the OpenShift version:

**telco-core**:
- `telco-core/install/example-standard-clusterinstace.yaml`

**telco-ran**:
- `telco-ran/configuration/argocd/example/clusterinstance/example-sno.yaml`
- `telco-ran/configuration/argocd/example/clusterinstance/example-3node.yaml`
- `telco-ran/configuration/argocd/example/clusterinstance/example-standard.yaml`

Change: `clusterImageSetNameRef: "openshift-4.22"` → `"openshift-4.23"`


### 7. Other locations
Other versioning information to be reviewed and updated
- Annotations added in PolicyGenerator overlay patches to trigger non-compliance, eg `noop-for-triggering-noncompliance: "22"`
- Descriptive text in metadata.yaml, eg `This reference was designed for OpenShift 4.22`
- URL locations in metadata.yaml -- Review all URLs for version number and update
- OperatorStatus reference-crs and PolicyGenerator overlay patches. Review ClusterServiceVersion fields for version update.
- The telco-core reference subscription validator `telco-core/configuration/reference-crs/custom-manifests/subscription-validator.yaml` must be updated: `ztp-validated: "4.22"` → `"4.23"`


## Version Numbering Patterns

Understanding different operator versioning schemes:

| Operator | Format | Example | Aligns With |
|----------|--------|---------|-------------|
| OpenShift Platform | `4.X` | `4.22`, `4.23` | Release number |
| NROP | `4.X` | `4.22`, `4.23` | OpenShift version |
| ODF | `stable-4.X` | `stable-4.22` | OpenShift version (with delay) |
| Cluster Logging | `stable-X.Y` | `stable-6.4` | Independent versioning |
| GitOps | `gitops-X.Y` | `gitops-1.19` | Independent versioning |
| ACM | `release-X.Y` | `release-2.17` (for OCP 4.22) | Independent versioning |
| MCE | `stable-X.Y` | `stable-2.12` (for OCP 4.22) | Aligns with ACM version |
| TALM, MetalLB, SR-IOV | `stable` | `stable` | Rolling channel |

## Common Pitfalls

1. **Forgetting kube-compare variants**: Always update both the reference-crs AND kube-compare versions of files
2. **ODF timing**: Don't update ODF to matching version immediately - wait for ODF GA (2-4 weeks after OpenShift)
3. **PolicyGenerator names**: Update both the PolicyGenerator CR name (metadata.name) AND the policy names within it
4. **Upgrade policy**: The `core-upgrade.yaml` represents upgrading TO the new version, so use the target version number
5. **All ODF operators**: There are 13+ ODF-related operators in imageset-config.yaml - update them all to be aligned with ODF
6. **Image tags**: Update version tags in image references found in PolicyGenerator and reference CRs.
7. **README files**: Don't update version references in README.md files (they're documentation/examples)
8. **Deprecated files**: Don't update any version references in files in `deprecated` directories
9. **Tekton files**: Don't update any version references in the `.tekton` directory
10. **Dockerfile**: Don't update any version references in `Dockerfile` files


## File Search Patterns

When updating versions, search for these patterns:

```bash
# Find operator subscription files
grep -r "^kind: Subscription" --include="*.yaml" telco-*

# Find policy generator files
grep -r "^kind: PolicyGenerator" --include="*.yaml" telco-*

# Find version-specific references
grep -r "4\.[12][0-9]\|stable-4\.[12][0-9]" --include="*.yaml" telco-*

# Find ClusterInstance examples
grep -r "^kind: ClusterInstance"
```

## Testing After Updates

1. Verify no stale version references remain:
   ```bash
   grep -r "4\.22" --include="*.yaml" telco-* | grep -v "README"
   ```

2. Check all subscription channels were updated:
   ```bash
   grep -r "channel:" --include="*.yaml" telco-*/configuration
   ```

3. Check all images were updated:
   ```bash
   grep -r "image:" --include="*.yaml" telco-*/configuration
   ```

4. Ensure policy generator names are consistent:
   ```bash
   grep "name: core-.*-4.23" telco-core/configuration/*.yaml
   ```

## Commit Message Template

```
Update all version references for OpenShift 4.23
- ACM: 2.18
- MCE: 2.13
- GitOps Operator: 1.20
- Cluster Logging Operator: 6.5
- ODF: 4.22

- Update policy generators and configurations
- Update ClusterInstance examples to openshift-4.23
- Update day-2 operator subscriptions and catalog source images
- Update subscription validator annotation
- Update mirror registry
- Update documentation: metadata.yaml URLs from 4.22 to 4.23
```
