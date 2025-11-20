# Hub-side policy for managing `MachineConfig` resources from extra-manifest ConfigMaps

**Setup**: Can be applied before or after cluster installation.

**Matching**: Applies to managed clusters with `ztp-done: ""` label.

**Functionality**:
- Synchronizes MachineConfigs on the managedclusters when changes are made to the MachineConfigs in the ClusterInstance `extraManifestsRefs` ConfigMaps.
- Labels managed MachineConfigs with `managed-by-ztp: "true"`.
- Can be used to add, remove or update existing MachineConfigs as a day-2 operation.
- Ignores non-MachineConfig resources in extra-manifests (Namespaces, etc.).

**Rollout**: Changes to MachineConfigs would trigger node reboots. The Policy can be applied in `enforce` mode, but `inform` mode is recommended for rollout through a ClusterGroupUpgrade(CGU) CR by [TALM](https://github.com/openshift-kni/cluster-group-upgrades-operator) during a maintenance window.

Example CR:

```yaml
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  name: cgu-apply-extra-manifests
  namespace: ztp-sno-ran-du
spec:
  clusters:
  - cluster-name
  managedPolicies:
  - extra-manifests-policy
  remediationStrategy:
    maxConcurrency: 1
  enable: true
```

**Note**: 
- If using custom day-2 patches for MachineConfigs, remove them and make updates directly in extra-manifest ConfigMaps to avoid Policy conflicts.
