
# Installation artifacts

This directory contains example CRs for installation of a Telco Core cluster
using [Multi Cluster
Engine (MCE)](https://github.com/stolostron/deploy/tree/master/multiclusterengine). The
CRs contained here are examples and must be tuned/configured to your particular
hardware and environment. However these represent the best-practices and the
general pattern shown here is recommended.

The contents of this directory fall into 3 categories. Each of these are
described in more detail in the following sections:

- example-standard.yaml -- A SiteConfig CR which defines the cluster
- extra-manifests -- Additional reference CRs to apply to the cluster during installation
- custom-manifests -- Additional custom/user specific CRs to apply to the cluster during installation

## SiteConfig CRs

The example-standard.yaml file contains a SiteConfig CR which defines the
topology and specific attributes of a cluster. This CR may be rendered into MCE
installation CRs using the [SiteGen
utility](https://github.com/openshift-kni/cnf-features-deploy/tree/master/ztp/siteconfig-generator). The
SiteConfig defines:

- cluster identity -- name, FQDN, API/ingress VIPs, etc
- cluster topology -- number of control plane and nodes, node labels for allocation to Machine Config Pools, etc
- cludter networking -- per-node network interface details, cluster networking attributes, etc
- node attributes -- ignition config may be provided to partition disks per node

## extra-manifests

Reference `MachineConfig` and `MachineConfigPool` CRs for Telco Core live **only**
in this directory. They are applied during installation (for example via
`ClusterInstance.spec.extraManifestsRefs`) and are the single copy in git; the
same content is validated at day-N using the Hub **extra-manifests** policy
(see `telco-hub/configuration/reference-crs/required/gitops/ztp-policies/extra-manifests-policy.yaml`).

The cluster-compare reference under `../configuration/reference-crs-kube-compare/`
is kept aligned with these files via `make compare_extra_manifests` in `../configuration`
(part of `make check`).

Reference `MachineConfig` files in this directory:

- `control-plane-load-kernel-modules.yaml`
- `worker-load-kernel-modules.yaml`
- `mount_namespace_config_master.yaml`
- `mount_namespace_config_worker.yaml`
- `kdump-master.yaml`
- `kdump-worker.yaml`
- `mc_rootless_pods_selinux.yaml`
- `sctp_module_mc.yaml`
- `mcp-worker-1.yaml`, `mcp-worker-2.yaml`, `mcp-worker-3.yaml` (`MachineConfigPool`)

The same three MCP files are duplicated under
`../configuration/reference-crs/custom-manifests/` for PolicyGenerator paths
(the plugin cannot reference `../install/`). `compare.sh --check-extra-manifests`
keeps install and custom-manifests copies in sync.

## custom-manifests

Optional additional manifests you maintain locally (see `README.md` in this
directory). Add a `ConfigMap` reference under `ClusterInstance.spec.extraManifestsRefs`
when you use this directory. The example `ClusterInstance` only references the
reference `extra-manifests-configmap` by default.
