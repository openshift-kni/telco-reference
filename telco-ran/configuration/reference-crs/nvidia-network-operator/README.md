# NVIDIA Network Operator

Install package `nvidia-network-operator`, channel `v26.7`, starting CSV
`nvidia-network-operator.v26.7.0-1`, with Manual install-plan approval.
The OperatorGroup watches its own namespace, as required by the certified bundle.
Deliver installation and configuration using hub inform policies and TALM CGUs.

## Sample NicClusterPolicy

[`NicClusterPolicy.yaml`](NicClusterPolicy.yaml) is an illustrative operand
configuration, not an enforced reference requirement. Customers and partners own
its contents and select component versions with NVIDIA. It is not included in
the baseline/group policies or kube-compare validation. Copy and customize it for
your deployment after installing the operator.

The sample enables the precompiled DOCA driver and DOCA Telemetry Service.
Reuse the shared Red Hat NFD deployment and OpenShift's
Multus, CNI plugins and SR-IOV Network Operator. Avoid allocating the same NIC
through multiple device plugins. Add RDMA shared-device resources only for
explicitly selected interfaces that are not owned by another resource pool.

Before applying the sample, create the `ofed-pull-secret` image pull secret
in the `nvidia-network-operator` namespace with credentials for your mirror.
Update `spec.ofedDriver.imagePullSecrets` if you use a different secret name.

Select and mirror a matching image for every target kernel and verify the
signer's trust before Secure Boot testing. `forcePrecompiled: true` prevents
fallback to runtime compilation. Image-content inspection alone does not prove
successful loading or Secure Boot acceptance.

## DOCA telemetry metrics

Include `DocaTelemetryService.yaml`, `DocaTelemetryServiceMonitor.yaml`,
`DocaTelemetryRole.yaml` and `DocaTelemetryRoleBinding.yaml` alongside
`NicClusterPolicy.yaml` in the operand policy to collect the existing DOCA
telemetry metrics on port 9189. The namespace must be enabled for OpenShift
cluster monitoring. Verify Prometheus target health and collected metrics after
policy remediation. These resources do not define alerts or custom GPU metrics.

The namespace-scoped Role grants `openshift-monitoring/prometheus-k8s` read-only
discovery of Services, Endpoints and Pods. The RoleBinding is required for
Prometheus to discover the exporter target.

## SR-IOV with Secure Boot

For Mellanox NICs, follow Red Hat's [Secure Boot SR-IOV procedure](https://docs.redhat.com/en/documentation/openshift_container_platform/5.1/html/hardware_networks/configuring-sriov-device#configuring-the-sr-iov-network-operator-on-mellanox-cards-when-secure-boot-is-enabled).
Configure and verify the firmware SR-IOV enablement and maximum VF capacity
before enabling Secure Boot. Add the following field to the owning policy for
the existing `SriovOperatorConfig`:

```yaml
spec:
  disablePlugins:
    - mellanox
```

This skips the SR-IOV operator's Mellanox firmware configuration plugin; it does
not disable the NIC driver or kernel lockdown. Preserve other existing plugin
exclusions. Verify `SriovNetworkNodeState` reaches `Succeeded`, requested VFs
exist and the device plugin is Ready before scheduling SR-IOV workloads.
Kernel-reported VF capacity alone is not a direct query of persistent firmware
settings. This prerequisite is conditional on Secure Boot and Mellanox hardware;
do not apply it universally to other deployment configurations.
