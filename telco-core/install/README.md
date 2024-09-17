
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
 - extra-manifests -- Additional reference CRs to apply to the cluster during
   installation
 - custom-manifests -- Additional custom/user specific CRs to apply to the
   cluster during installation

## SiteConfig CRs
The example-standard.yaml file contains a SiteConfig CR which defines the
topology and specific attributes of a cluster. This CR may be rendered into MCE
installation CRs using the [SiteGen
utility](https://github.com/openshift-kni/cnf-features-deploy/tree/master/ztp/siteconfig-generator). The
SiteConfig defines:
 - cluster identity -- name, FQDN, API/ingress VIPs, etc
 - cluster topology -- number of control plane and nodes, node labels for
   allocation to Machine Config Pools, etc
 - clsuter networking -- per-node network interface details, cluster networking
   attributes, etc
 - node attributes -- ignition config may be provided to partition disks per
   node


## extra-manifests
The CRs in extra-manifests are exact copies of some CRs from the
../configuration tree. These CRs will be applied during installation to
accelerate the time to cluster-ready.

## custom-manifests
These CRs are an additional set of CRs which you want to apply to the cluster
during installation. The CRs here are treated in the same way as the
extra-manifests directory but are separated to make it easier to update the set
of reference manifests when new versions are released.

The example manifests included here define two Machine Config Pools for the
cluster which bind nodes based on the node-role.kubernetes.io label. The
examples here also set the Machine Config Pools to `paused: true` and
`maxUnavailable: 100%`. This results in a significant improvement in install
times by allowing all worker nodes to update simultaneously (before any workload
is applied). The assumption is that post-installation the Machine Config Pools
will be set to `paused: false` and when nodes are ready the MCP set to a
reasonable `maxUnavailable: <value>` for your use case.
