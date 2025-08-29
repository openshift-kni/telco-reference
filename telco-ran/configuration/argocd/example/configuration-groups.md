# Motivation
When using hub side templating, we can have fewer PGTs to configure and manage our spokes.

Each group/site PGT can use templates for its specific configuration that can be further obtained from ConfigMaps.

Below are options for grouping source CRs into PGTs in the templating scenario.
Depending on the exact purpose and configuration for the spokes, some of the source CRs could be either common to all spokes or to different groups.

# PGT1 - configuration that can be common for most spoke clusters
**The source CRs from below could lack group or site specific info and can have common configuration for all spokes**
* cluster-logging/ClusterLogForwarder.yaml
    * spec.outputs
    * spec.pipelines
* cluster-tuning/DisableOLMPprof.yaml
* cluster-tuning/disabling-network-diagnostics/DisableSnoNetworkDiag.yaml (Cluster Network Operator)
* image-registry/ImageRegistryConfig.yaml (Cluster Image Registry Operator)
* image-registry/ImageRegistryPV.yaml
* generic/MachineConfigGeneric.yaml
* machine-config/MachineConfigPool.yaml
* machine-config/MachineConfigSctp.yaml
* cluster-tuning/operator-hub/OperatorHub.yaml
* storage-lso/StorageClass.yaml
* storage-lso/StoragePV.yaml (Local Storage Operator)
* storage-lso/StoragePVC.yaml (Local Storage Operator)


# PGT2 - has configuration that can be common to sites with the same hardware(disks, NICs)/OS, mountpoints, etc
* cluster-logging/ClusterLogForwarder.yaml
    * spec.outputs
    * spec.pipelines
* cluster-tuning/disabling-network-diagnostics/DisableSnoNetworkDiag.yaml (Cluster Network Operator)
    > Note: If users want to configure things apart spec.disableNetworkDiagnostics
* image-registry/ImageRegistryConfig.yaml (Image Registry Operator)
    > Note: Any of the spec fields can differ based on the spokes groups
* image-registry/ImageRegistryPV.yaml
    > Note: Any of the spec fields can differ based on the spokes groups
* node-tuning-operator/PerformanceProfile.yaml / node-tuning-operator/PerformanceProfile-SetSelector.yaml 
    * spec.cpu.isolated, spec.cpu.reserved
    * spec.hugepages.pages.(size/count/node), spec.hugepages.defaultHugepagesSize
* node-tuning-operator/TunedPerformancePatch.yaml
* generic/MachineConfigGeneric.yaml
* machine-config/MachineConfigPool.yaml
* machine-config/MachineConfigSctp.yaml
* ptp-operator/PtpOperatorConfigForEvent.yaml / ptp-operator/PtpOperatorConfigForEvent-SetSelector.yam / ptp-operator/PtpOperatorConfig.yaml
* ptp-config/PtpConfig<Boundary/Slave/GmWpc/Master/Slave/SlaveCvl>.yaml DU example
    * spec.profile.interface from ConfigMap
* sriov-operator/SriovNetwork.yaml
* sriov-operator/SriovNetworkNodePolicy.yaml / sriov-operator/SriovNetworkNodePolicy-SetSelector.yaml
* sriov-operator/SriovOperatorConfig.yaml
* image-registry/ImageRegistryConfig.yaml (Image Registry Operator)
* image-registry/ImageRegistryPV.yaml
* storage/StorageLocalVolume.yaml
    > Note: could be common to all spokes, depending on the exact disk configuration, but safer to have it per-site (Local Storage Operator)
    * spec.devicePaths
* storage-lso/StorageClass.yaml
* storage-lvm/StorageLVMCluster.yaml
* storage-lso/StoragePV.yaml
* storage-lso/StoragePVC.yaml

# PGT3 - has config that is (can be) site specific
* sriov-fec-operator/SriovFecClusterConfig.yaml
    * spec.acceleratorSelector.pciAddress
    * spec.physicalFunction.bbDevConfig
* sriov-operator/SriovNetwork.yaml
* sriov-operator/SriovNetworkNodePolicy.yaml / sriov-operator/SriovNetworkNodePolicy-SetSelector.yaml
* storage/StorageLocalVolume.yaml
    * spec.devicePaths
