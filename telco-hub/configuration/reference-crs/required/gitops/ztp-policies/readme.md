# Hub-side policy for managing `MachineConfig` resources from extra-manifest ConfigMaps

**Setup**: Can be applied before or after cluster installation.

**Matching**: Applies to managed clusters with `ztp-done: ""` label.

**Functionality**:
- Synchronizes MachineConfigs on the managedclusters when changes are made to the MachineConfigs in the ClusterInstance `extraManifestsRefs` ConfigMaps.
- Labels managed MachineConfigs with `managed-by-ztp: "true"`.
- Can be used to add, remove or update existing MachineConfigs as a day-2 operation.
- Ignores non-MachineConfig resources in extra-manifests (Namespaces, etc.).

**Note**: If using custom day-2 patches for MachineConfigs, remove them and make updates directly in extra-manifest ConfigMaps to avoid Policy conflicts.