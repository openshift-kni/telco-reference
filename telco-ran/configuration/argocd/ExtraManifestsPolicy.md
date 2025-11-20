## Extra Manifests Policy

Extra-manifests are install-time CRs that are referenced in ClusterInstance through `extraManifestsRef` and installed by the [siteconfig operator](https://github.com/stolostron/siteconfig) as a day-0 operation.

For managing MachineConfig resources applied through extra-manifests as a day2 operation, apply the [extra-manifests-policy](../../../telco-hub/configuration/reference-crs/required/gitops/ztp-policies/extra-manifests-policy.yaml). More details in [readme](../../../telco-hub/configuration/reference-crs/required/gitops/ztp-policies/readme.md).