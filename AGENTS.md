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

## Working with References

### Hub RDS (telco-hub)

The Hub RDS is directly applied using ArgoCD. Each CR has a sync wave associated via the `argocd.argoproj.io/sync-wave` annotation. These sync waves provide ordering to ensure prerequisites are in place before dependent resources are created.

**Sync wave values used:**
- `-50`: Registry foundation (OperatorHub, CatalogSource, IDMS, ITMS)
- `-45`: Namespaces
- `-40`: Namespaced resources (RBAC, Subscriptions, OperatorGroups)
- `-35`: ArgoCD resources
- `-30`: Independent CRs (MCE, MCH, StorageCluster)
- `-25`: Policies and validation
- `-10`: Storage-dependent services
- `100`: ZTP components (final phase)

**Pattern:** Negative values ensure infrastructure phases complete before workloads. When adding new resources, read the existing configuration and follow the established wave ordering patterns.

**Detailed reference:** See `telco-hub/configuration/SYNC-WAVES.md` for complete wave ordering documentation (68 resources across 8 waves).

**Component Registration:**

The Hub RDS is built as a kustomize application. The top level `telco-hub/configuration/kustomization.yaml` serves as the single source of truth for all components in the Hub reference.

**IMPORTANT:** All components (required and optional) must be represented in `telco-hub/configuration/kustomization.yaml`:
- **Optional components not included by default**: Must be listed as commented-out entries in the kustomization.yaml
- **Optional components included by default**: Must be listed as uncommented entries
- **Required components**: Must be listed as uncommented entries

This ensures that all available components are discoverable and documented in a single location. When adding new components, always add them to the top-level kustomization.yaml file, commented out if they are optional and not included by default.

### Core and RAN RDS (telco-core, telco-ran)

The Core and RAN RDS are applied through ACM policies. The configuration uses PolicyGenerator CRs to define the contents of these policies. These policies are structured to order the application of CRs based on prerequisites.

**Policy ordering:** The `ran.openshift.io/ztp-deploy-wave` annotation on the policies determines the order in which they are applied. Similar to Hub RDS, policies create resources in a logical sequence.

**Common ztp-deploy-wave values:**
- `1-2`: Base cluster configuration and overlays
- `5`: Operator subscriptions
- `7-8`: Operator configuration and custom overlays
- `10-11`: Advanced configuration
- `100+`: Validation and cleanup
- `200+`: Upgrade orchestration

**Important:** With PolicyGenerator, the `ztp-deploy-wave` annotation is applied to the Policy itself, not to individual CRs. The wave value is specified in the PolicyGenerator CR and applies to the entire policy.

**Component Registration:**

All components (required and optional) must be represented in one or more PolicyGenerator CRs:
- **Core RDS**: Components must be in PolicyGenerator files in the `telco-core/configuration/` directory (e.g., `core-baseline.yaml`, `core-overlay.yaml`)
- **RAN RDS**: Components must be in PolicyGenerator files in the `telco-ran/configuration/argocd/example/acmpolicygenerator/` directory

**IMPORTANT:** All components must be represented in these PolicyGenerator files:
- **Optional components not included by default**: Must be listed as commented-out manifest entries within the PolicyGenerator
- **Optional components included by default**: Must be listed as uncommented manifest entries
- **Required components**: Must be listed as uncommented manifest entries

This ensures that all available components are discoverable and documented in the PolicyGenerator files. When adding new components, always add them to the appropriate PolicyGenerator CR(s), commented out if they are optional and not included by default.

**Adding new content:**

- **Prefer existing policies**: When adding new content, fit it into existing policies where it makes sense to do so. Research the patterns in the repository and follow them.

- **Environment-specific customization**: When adding environment-specific content to the reference, prefer hub-side templating as the primary mechanism.
  - Prescriptive values and reasonable defaults should be included in the `reference-crs/` or `source-crs/` directories as the base configuration.
  - Hub-side templating should be used for simple value substitution and most customization needs.
  - Patches/overlays should only be used when the complexity of the change makes templating difficult (e.g., large structured content or complex nested objects).
  - When patches are necessary, include commented examples to indicate where users should provide environment-specific content.

- **Important limitation**: When patching lists in PolicyGenerator, the entire list is replaced (no merge behavior). To modify a list item, include the complete list in the patch.

### Hub-Side Templating

ACM PolicyGenerator supports Go templating with hub-side functions for dynamic value injection:

**Basic syntax:**
```yaml
value: '{{hub fromConfigMap "" "configmap-name" "key" hub}}'
```

**Available functions:**
- `fromConfigMap "" "cm-name" "key"` - Read value from ConfigMap on hub cluster
- `toLiteral` - Convert to literal string (for JSON/YAML content)
- `toInt` - Convert to integer
- `printf` - String formatting for dynamic key construction
- `index .ManagedClusterLabels "label-name"` - Access cluster labels

**Example (from telco-core):**
```yaml
cpu:
  isolated: '{{hub fromConfigMap "" "hw-types" "role-worker-1-isolated" | toLiteral hub}}'
  reserved: '{{hub fromConfigMap "" "hw-types" "role-worker-1-reserved" | toLiteral hub}}'
```

**Example (from telco-ran with dynamic keys):**
```yaml
interface: '{{hub fromConfigMap "" "group-hardware-types-configmap" (printf "%s-ptpcfgslave-profile-interface" (index .ManagedClusterLabels "hardware-type")) hub}}'
```

**Important:** ConfigMaps referenced in templates must exist on the hub cluster BEFORE policy enforcement begins. Additionally, ConfigMaps MUST exist in the same namespace as the policy itself. Security restrictions prevent arbitrary lookups in the cluster - only resources in the same namespace as the policy can be accessed by hub-side templates.

**Detailed guides:**
- `telco-core/configuration/README.md` - Templating patterns, ConfigMap usage, upgrade orchestration
- `telco-ran/configuration/argocd/README.md` - ACM/MCE version compatibility, GitOps setup, ZTP requirements
- `telco-ran/configuration/argocd/example/acmpolicygenerator/README.md` - PolicyGenerator vs PolicyGenTemplate comparison, patching strategies

## Testing and Validation

Before committing changes to any reference configuration, run validation checks:

**Syntax validation:**
```bash
make ci-validate  # Runs yamllint and comparison checks
```

**Reference synchronization:**

The repository maintains dual structures for validation:
- **telco-core**: `reference-crs/` ↔ `reference-crs-kube-compare/`
- **telco-ran**: `source-crs/` ↔ `kube-compare-reference/`

These must stay in sync. Verify with:
```bash
make compare  # Validates sync between deployable and validation variants
```

**Runtime validation:**

Use kube-compare tool to validate CRs against live cluster state:
- Validation templates in `*-kube-compare/` directories
- Custom validation functions in `.tmpl` files
- Rules defined in `metadata.yaml`

**Important:** When adding new CRs, they must be added to BOTH the deployable directory AND the corresponding kube-compare directory.

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
