# TNC VEWL configuration

## Structure

This directory contains the key components of the TNC Virtualized Edge Workload
(VEWL) configuration:

- The `reference-crs` tree contains the baseline configuration CRs which make
  up the RDS Core reference configuration. These are further separated into
  optional vs required configuration.
- The `other-crs` tree contains the configuration that is added by TNC to
  augment the baseline RDS configuration for VEWL workloads. These are further
  separated into optional vs required configuration. Required content includes
  VEWL VM networking, the Containerized Virtualization (CNV) operator, and
  supporting manifests such as IDMS.
- The yaml files at this top level support application and ongoing management
  of the reference configuration using Advanced Cluster Management (ACM)
  Policy. These yaml files define how CRs from the `reference-crs` and
  `other-crs` trees are grouped into policies and how use-case-specific patches
  are applied to the policy-wrapped CRs.
- The `template-values` directory holds ConfigMaps which provide values used in
  the ACM Policies. See the "Templating" section below for more details.
- (Future) The `tnc-crs-kube-compare` tree contains the template copy of the
  TNC configuration for use by the
  [cluster-compare tool](https://github.com/openshift/kube-compare).

## Reference CRs

### Policy generation CRs

The repository includes several PolicyGenerator CRs named `vewl-xxx.yaml` at
this top level. These CRs serve as manifests and customization of the
`reference-crs` and `other-crs` configuration. The PolicyGenerator CR is
turned into ACM Policy CRs which can then be used to configure one or more
clusters with the VEWL sub-architecture configuration. When these
PolicyGenerator CRs and the reference-crs that they enumerate are stored in a
Git repository the [PolicyGenerator
GitOps/ArgoCD](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/governance/policy-deployment#policy-generator)
plugin will automatically convert them when synchronizing to a hub cluster.

#### Policy Generators

The repository provides the following policy generators:

* `vewl-baseline` contains fixed required RDS content such as operator hub,
  catalog source, scheduler, operator subscriptions (SR-IOV, ODF, MetalLB,
  NROP, NMState, cluster logging), and operator configuration.
* `vewl-overlay` contains RDS content where updates and patches are expected.
  This includes performance profiles for three worker MCPs, NUMA-aware
  scheduling, SR-IOV networking for VM workloads, ODF external storage
  configuration, and cluster monitoring customization.
* `vewl-additions` contains VEWL-specific configuration added by TNC:
  - VEWL VM networking (OVS bridge NNCP, workload namespace, ClusterUserDefinedNetwork)
  - Containerized Virtualization (CNV) operator installation and HyperConverged CR
* `vewl-odf-external` configures the OpenShift cluster to use ODF in external
  mode, including storage class, console, dummy MetalLB address pool, monitoring,
  and CMA storage configuration.
* `vewl-odf-internal` configures the OpenShift cluster to use ODF in internal
  mode via Local Storage Operator (LSO) and internal ODF storage cluster
  configuration.
* `vewl-finish` contains policies which release/un-pause custom
  MachineConfigPool worker nodes (`worker-1`, `worker-2`, `worker-3`). These are
  typically independent of version and only need to be defined once.
* `vewl-upgrade` contains policies to prepare a cluster for an OpenShift
  version upgrade (catalog source update, MCP maxUnavailable adjustment).
* `vewl-upgrade-finish` contains post-upgrade policies to restore MCP
  configuration after an upgrade completes.

The active generators and template resources are listed in `kustomization.yaml`.
Additional generators above are available in the repository and can be enabled
by adding them to that file.

#### Cluster labels

Apply the following labels to ManagedClusters to configure them with the
appropriate VEWL policies:

- `common: "core"` — To apply the RDS baseline and overlay policies
- `version: "4.20"` — To pick the RDS 4.20 policies
- `vewl: "true"` — To apply the TNC VEWL policies
- `tnc-ver: "tnc6.1"` — To pick TNC 6.1 policies
- Pick one of the following:
  - `odf-ext: "true"` — To configure ODF in external mode
  - `odf-int: "true"` — To configure ODF in internal mode

Optional labels for future or site-specific use:

- `nic-config: "type-1"` — To select SR-IOV NIC configuration profile
- `upgrade-version-4-19` — To apply upgrade preparation policies (empty value label)

#### Node labels

The VEWL overlay defines three custom worker MachineConfigPools with matching
PerformanceProfiles. Nodes must be labeled appropriately for tuning and SR-IOV
policies to apply:

- `node-role.kubernetes.io/worker-1: ""`
- `node-role.kubernetes.io/worker-2: ""`
- `node-role.kubernetes.io/worker-3: ""`

SR-IOV configuration in `vewl-overlay` is currently targeted at `worker-1`
nodes.

Workload namespaces used by VEWL VM networking are labeled with
`vewl-network: "true"` so they can attach to the ClusterUserDefinedNetwork.

#### Templating

These PolicyGenerator CRs create Policies which include ACM hub-side templates.
These templates pull values from ConfigMaps in the `template-values` directory.

`template-values/hw-types` — Hardware-dependent data.

- Keys are based on hardware profiles (MCP names) as defined in `vewl-overlay`.
- Used for PerformanceProfile CPU reservation, isolation, and hugepage counts.
- Example keys: `role-worker-1-reserved`, `role-worker-1-isolated`,
  `role-worker-1-hugepg-cnt`.

`template-values/vewl-conf` — VEWL-specific configuration values.

- Consolidates hardware profile data and VEWL SR-IOV settings in one ConfigMap.
- Example keys: `nic-config-type-1-sriov-dev1`, `nic-config-type-1-sriov-dev2`,
  `nic-config-type-1-sriov-numvf`, `vewl-namespace`.

`template-values/cwl-site3` — Site-specific values.

- Used when lab or site parameters differ from generic hardware profiles.
- Currently referenced by `vewl-overlay` for SR-IOV NIC selection, VF count, and
  workload namespace.
- Also holds site parameters such as Kafka broker, Vault server, and MetalLB
  settings for optional components.

`template-values/regional` — Values which may depend on the region or zone where
a cluster is deployed.

- Keyed by a `region` label on the ManagedCluster.
- Example: `%s-log-url` — a cluster labeled `region: zone-1` would use
  `zone-1-log-url` from the regional ConfigMap.

`<clusterName>` — Values which are cluster specific. One ConfigMap per cluster
is needed. The ConfigMap name is the cluster name, for example `cluster-1234`.

Hub template lookups use an empty namespace (`""`) in `fromConfigMap`, which
resolves ConfigMaps in the policy namespace (`ztp-core-policies`). Ensure the
required ConfigMaps are deployed to the hub and contain the keys referenced by
the policies before the policies propagate to managed clusters.

#### VEWL features configured by these artifacts

The active VEWL configuration delivers the following capabilities:

**Core platform (baseline and overlay)**

- Operator hub, catalog source, and cluster scheduler
- Operator subscriptions for SR-IOV, ODF, MetalLB, NROP, NMState, and cluster
  logging (manual install plan approval)
- Kernel module MachineConfigs, SCTP module, and rootless pod SELinux settings
- Control-plane system reserved tuning
- Three PerformanceProfiles bound to `worker-1`, `worker-2`, and `worker-3` MCPs
- NUMA-aware scheduling via NROP, bound to the `worker-1` MCP
- SR-IOV network (`vm-sriov-net`) for VM passthrough on `worker-1` nodes
- ODF external storage cluster configuration
- Cluster monitoring PVCs backed by ODF and external Alertmanager integration

**VEWL additions**

- NodeNetworkConfigurationPolicy for OVS bridge bonding
- Workload namespace (`vewl-epa`) for VEWL VMs
- ClusterUserDefinedNetwork for localnet secondary networking (VLAN 64)
- CNV operator and HyperConverged cluster configuration

**Optional components available in `other-crs/optional`**

Additional CRs are provided for optional integrations and can be wired into new
PolicyGenerator manifests as needed, including authentication (IDM, Keycloak,
local), observability (Loki, Tempo, OTEL), availability (self-node remediation,
node health checks), compliance operator, vault/external secrets, and lab-only
components.
