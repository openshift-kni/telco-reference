# ACM PolicyGenerator

The [policy-generator-plugin](https://github.com/stolostron/policy-generator-plugin) examples in this directory define the DU profile policies using the [ACM PolicyGenerator reference API](https://github.com/stolostron/policy-generator-plugin/blob/main/docs/policygenerator-reference.yaml).

Group policies use hub-side templating with ConfigMaps in `../template-values/` for hardware-type, zone, and site-specific values. Separate per-site PolicyGenerator CRs are not needed.

## Editing example templates

Create the PolicyGenerator CRs for your site in your local clone of the git repository:

1. Begin by choosing an appropriate example from this directory. It demonstrates a 2-level policy framework which represents a well-supported low-latency profile tuned for the needs of 5G Telco DU deployments:
   - A single [ran-common.yaml](ran-common.yaml) should be applied to SNO. DO NOT USE [ran-common-mno.yaml](ran-common-mno.yaml) for SNO clusters.
   - For MNO clusters, it will require both [ran-common.yaml](ran-common.yaml) and [ran-common-mno.yaml](ran-common-mno.yaml).
   - A set of shared `ran-group-du-*-templated.yaml`, each of which should be common across a set of similar clusters. These use hub-side templating with ConfigMaps in `../template-values/` for hardware-type, zone, and site-specific values.
   > **Note:** Depending on the specific requirements of your clusters, you may need more than just a single group policy per cluster type, especially considering the example group policies each has a single PerformanceProfile which can only be shared across a set of clusters if those clusters consist of identical hardware configurations.
2. Ensure the labels defined in your PolicyGenerator's `placement.labelSelector` section correspond to the proper labels defined on the ClusterInstance file(s) of the clusters you are managing.
3. Ensure the content of the overlaid spec files matches your desired end state. As a reference, the `../source-crs/` directory contains the full set of source CRs available to be included and overlaid by your PolicyGenerator templates.
4. Define all the policy namespaces in a yaml file much like in [ns.yaml](ns.yaml).
5. Add all the PolicyGenerator CRs and `ns.yaml` to the `kustomization.yaml` file, much like in [kustomization.yaml](kustomization.yaml).
6. Commit the PolicyGenerator CRs, `ns.yaml`, and associated `kustomization.yaml` in git.
7. Push your changes to the git repository, and the ArgoCD pipeline will detect the changes and begin the site deployment. The ClusterInstance and PolicyGenerator CRs can be pushed simultaneously.
   > **Note**: The PolicyGenerator CRs and associated `ns.yaml`, `kustomization.yaml` must be pushed to the git repository within 20 minutes after the ClusterInstance is pushed.

## ManagedClusterSetBinding

A ManagedClusterSet groups managed clusters with the same access rights. In ZTP, the default clusterset is named `global`. With PolicyGenerator, it is required to specify a clusterset binding. The ManagedClusterSetBinding adds a namespace to the list of namespaces allowed to manage the clusters in the clusterset.

The ManagedClusterSetBinding can be added to the `ns.yaml` file. The example below adds the `ztp-common`, `ztp-group` and `ztp-site` namespaces to the `global` clusterset:

```yaml
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: global
  namespace: ztp-common
spec:
  clusterSet: global
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: global
  namespace: ztp-group
spec:
  clusterSet: global
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: global
  namespace: ztp-site
spec:
  clusterSet: global
```

## Patching CR objects containing lists

By default, ACM PolicyGenerator replaces entire lists when patching. To enable strategic merge (matching list elements by key and merging fields), a `schema.openapi` file must be referenced from the PolicyGenerator manifest:

```yaml
manifests:
  - path: source-crs/ptp-operator/configuration/PtpConfigSlave.yaml
    patches:
      - spec:
          profile:
          - name: slave          # matched by merge key "name"
            interface: ens5f0    # only this field is patched
    openapi:
      path: schema.openapi      # enables list merging
```

Without the `openapi` directive, the patch above would replace the entire `spec.profile` array. With it, PolicyGenerator matches the element where `name: slave` and merges only the `interface` field, preserving other fields and other array elements.

### How the schema.openapi file works

The `schema.openapi` file is a JSON document containing OpenAPI schema definitions with strategic merge patch directives:

- `x-kubernetes-patch-strategy: merge` — marks an array as merge-capable
- `x-kubernetes-patch-merge-key: <field>` — specifies which field in array elements is used as the unique key for matching

These are the same directives Kubernetes uses internally for strategic merge patch on built-in resources. PolicyGenerator reads them to determine how to merge list patches.

### Atomic vs map-type lists

Not all lists support merge-by-key. There are two types:

- **Map-type lists** have elements with a natural unique key (e.g., PtpConfig `spec.profile[]` where each element has a unique `name`). These support strategic merge and have entries in `schema.openapi`.
- **Atomic lists** are simple arrays (e.g., `spec.additionalKernelArgs[]` in PerformanceProfile, or `spec.nicSelector.pfNames[]` in SriovNetworkNodePolicy). These have no merge key — the entire list is always replaced. No schema entry is needed for atomic lists.

### Generating and updating the schema

The `schema.openapi` files are generated artifacts produced by two scripts:

1. `hack/generate-schema-config.py` — scans Subscription CRs in the repo to auto-populate `hack/crd-schema-config.json` with CRD sources, channels, components, and git refs. The `merge_keys` and `version` fields in the config are manually maintained and preserved across regenerations.
2. `hack/extract-schema.py` — downloads CRDs from GitHub, extracts minimal merge directive schemas, and outputs `schema.openapi` files.

To regenerate everything:

```bash
make generate-openapi-schemas
```

This first runs `generate-schema-config` (updating `hack/crd-schema-config.json` from Subscription CRs), then regenerates the `schema.openapi` files.

Most CRDs do not include `x-kubernetes-list-type` annotations, so the merge keys are specified in the config based on domain knowledge of each CR's API.

### Updating for your environment

If your deployment uses CRs with lists not covered by the provided schema, you can extend it:

1. Obtain the CRD for your CR (from a cluster or operator GitHub repo):
   ```bash
   oc get crd <name> -o json > /tmp/mycrd.json
   ```
2. Extract the schema and identify list fields that need merge keys
3. Add the CRD to `hack/crd-schema-config.json` with appropriate merge keys
4. Run `make generate-openapi-schemas` to regenerate

The merge key for a list field is the field within each element that uniquely identifies it (typically `name`, but varies by API). Check the operator documentation or CRD source to determine the correct key.

## Controlled reboot of a fleet of clusters

Users can make tuning changes by applying tuned configurations on a running system. When the tuning change is done, the tuned process rolls back all the configurations and reapplies them. In some cases, latency sensitive applications cannot tolerate the removal/re-apply of the tuned profile. By adding the `tuned.openshift.io/deferred` annotation to the Tuned CR, application of the configuration can be deferred to the maintenance window. After rebooting the node the deferred tuning configuration will be applied.

PolicyGenerator `ran-example-reboot.yaml` can be used to reboot clusters. The policy generated contains a MachineConfig which will trigger a reboot when reconciled and a MachineConfigPool (MCP) validator which verifies that the MCP is successfully updated. These policies can be rolled out using CGU to desired clusters. In case of multi-node clusters the MCP should match the `Tuned.spec.recommended`. Note that all the nodes belonging to the MCP at the time of rolling out the policy will be rebooted.

When there are multiple config changes, all the config changes can be deferred and the reboot policy can be used to do a single reboot instead of rebooting for every config change. In this case, all the configuration changes can be put inside a CGU where the reboot policy is the last item in the CGU's `spec.managedPolicies`.

Note that if there are other MachineConfig changes which will trigger a reboot of nodes in the MCP, the examples given here are not required. Similarly, the MCP pause feature may also further defer the reboot of nodes regardless of the use of these policies.
