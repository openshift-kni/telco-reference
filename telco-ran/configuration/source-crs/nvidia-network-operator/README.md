# NVIDIA Network Operator

Install package `nvidia-network-operator`, channel `v26.7`, starting CSV
`nvidia-network-operator.v26.7.0-1`, with Manual install-plan approval.
The OperatorGroup watches its own namespace, as required by the certified bundle.
Deliver installation and configuration using hub inform policies and TALM CGUs.

The sample `NicClusterPolicy` enables the precompiled DOCA driver and DOCA
Telemetry Service. Reuse the shared Red Hat NFD deployment and OpenShift's
Multus, CNI plugins and SR-IOV Network Operator. Avoid allocating the same NIC
through multiple device plugins. Add RDMA shared-device resources only for
explicitly selected interfaces that are not owned by another resource pool.

The driver digest in this sample is a lab-validated image-content selection:
`registry.stage.redhat.io/nvidia/doca-driver-rhel10@sha256:02792cf44b818d2f1bb319a3df5907c4510331318e2add0152e723a5013050cf`.
Its `mlx5_core.ko` vermagic is
`6.12.0-211.69.1.el10_2.aarch64+64k`; it has an appended module signature.
Select and mirror a matching image for every target kernel and verify the
signer's trust before Secure Boot testing. `forcePrecompiled: true` prevents
fallback to runtime compilation. Image-content inspection alone does not prove
successful loading or Secure Boot acceptance.

## Functional validation

Record versions, kernel, NIC firmware, image digests, driver module provenance,
Secure Boot state, policy readiness and logs for each case.

| Check | Evidence required | Current status |
| --- | --- | --- |
| OLM | CSV Succeeded; NicClusterPolicy CRD Established | Pending |
| Precompiled driver | Driver ready; expected modules loaded; no runtime compilation | Image ABI matched; runtime pending |
| Secure Boot disabled | Firmware state, driver loading and networking pass | Pending |
| Secure Boot enabled | Trusted module signer, successful load, no signature rejection | Pending |
| Metrics | Exporter ready; endpoint counters; successful Prometheus scrape | Pending |
| Platform CPU | Compare idle platform CPU and reserved-CPU placement before/after; record requests | Pending |
| Pod kernel networking | Bidirectional connectivity over pod interfaces | Pending |
| Machine networking | Host connectivity to a peer over the selected NIC | Pending |
| SR-IOV kernel networking | VFs allocated; bidirectional pod connectivity using netdevice | Pending |
| SR-IOV DPDK | Existing DPDK test application forwards packets on allocated VFs | Pending |

Use existing connectivity tools and DPDK test applications. A packet-forwarding
check establishes functionality; throughput and latency benchmarking are outside
scope. Secure Boot changes require a coordinated reboot. Machine and SR-IOV
checks require a reachable peer and known NIC/switch connectivity.

Runtime driver compilation and customer-defined GPU alerts/metrics are excluded.
NIC-to-GPU DMA remains a feasibility item: first inspect the selected precompiled
GPU/DOCA drivers and peer-memory support, then decide whether a functional test
is possible. Do not claim this capability based only on operator readiness.

Include `DocaTelemetryService.yaml` and `DocaTelemetryServiceMonitor.yaml` alongside
`NicClusterPolicy.yaml` in the operand policy to collect the existing DOCA
telemetry metrics on port 9189. The namespace must be enabled for OpenShift
cluster monitoring. Verify Prometheus target health and collected metrics after
policy remediation. These resources do not define alerts or custom GPU metrics.
