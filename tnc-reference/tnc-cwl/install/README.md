
# Installation artifacts

This directory contains example CRs for installation of a Telco Core cluster
using [Multi Cluster
Engine (MCE)](https://github.com/stolostron/deploy/tree/master/multiclusterengine). The
CRs contained here are examples and must be tuned/configured to your particular
hardware and environment. However these represent the best-practices and the
general pattern shown here is recommended.

The contents of this directory fall into 4 categories. Each of these are
described in more detail in the following sections:

- example-standard.yaml -- A clusterInstance CR which defines the cluster
- extra-manifests -- Additional reference CRs to apply to the cluster during installation
- custom-manifests -- Additional custom/user specific CRs to apply to the cluster during installation
- secrets -- Credentials needed for cluster installation

## ClusterInstance CRs

The example-standard.yaml file contains a ClusterInstance CR which defines the
topology and specific attributes of a cluster. 
ClusterInstance defines:

- cluster identity -- name, FQDN, API/ingress VIPs, etc
- cluster topology -- number of control plane and nodes, node labels for allocation to Machine Config Pools, etc
- cludter networking -- per-node network interface details, cluster networking attributes, etc
- node attributes -- ignition config may be provided to partition disks per node

### Cluster labels

Apply the following labels to the clusters in order to configure them with the appropriate policies:

- common: "core"       - To apply the RDS baseline and overlay policies
- version: "4.20"      - To pick the RDS 4.20 policies
- region: "zone-1"     - Choose the appropriate zone name/number to pick the template variable values from `template-values/regional.yaml`
- cwl: "true"          - To apply the TNC CWL policies
- tnc-ver: "tnc6.1"    - To pick TNC 6.1 policies
- Pick one the following:
  - odf-ext: "true"    - To configure ODF in external mode
  - odf-int: "true"    - To configure ODF in internal mode
- kafka: "true"        - To configure logs and metrics to be sent to kafka
- idm: "true"          - To configure OAUTH for LDAP authentication
- lab: "true"          - To install optional components that are not suitable for production deployment

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

## secrets

Cluster installation requires access to the following credentials at a minimum:

* BMC/idrac credentials to be used by the installer to control the power state of the baremetal servers
* pull secret defining the credetials for accessing the private image registry

These secrets should be stored in a vault server and retrieved during cluster installation. This means that the presence of a vault server is a pre-requisite for installing the OpenShift cluster via ACM GitOps procedure as captured in this repository. 

If a vault server is not available then the CR(s) created in the `secrets` directory need to be updated to provide the credentials locally. However, this approach will result in pushing those credentials to the GIT server and hence appropriate procedures need to be put in place to protect the data in the GIT server, or the credentials need to be manually created prior to stating the GitOps process in order to avoid pushing them to the GIT server.

