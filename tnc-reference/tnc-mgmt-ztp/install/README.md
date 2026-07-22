
# Installation artifacts

This directory contains example CRs for installation of a TNC Management cluster
using [Multi Cluster
Engine (MCE)](https://github.com/stolostron/deploy/tree/master/multiclusterengine). The
CRs contained here are examples and must be tuned/configured to your particular
hardware and environment. However these represent the best-practices and the
general pattern shown here is recommended.

The contents of this directory fall into 3 categories. Each of these are
described in more detail in the following sections:

- example-standard.yaml -- A clusterInstance CR which defines the cluster
- extra-manifests -- Additional reference CRs to apply to the cluster during installation
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

- mgmt: "true"          - To apply the TNC Management cluster policies
- tnc-ver: "tnc6.1"     - To pick TNC 6.1 policies
- Pick one the following:
  - odf-ext: "true"     - To configure ODF in external mode
  - odf-int: "true"     - To configure ODF in internal mode
  - lvms: "true"         - To configure LVMS storage for SNO deployments
- kafka: "true"         - To install kafka and configure logs and metrics to be sent to kafka
- idm: "true"           - To configure OAUTH for LDAP authentication
- optional: "true"       - To install optional components: AAP, ACS

## extra-manifests

If its desired to apply some configuration to the cluster during installation
then the CRs for that configurtation can be specified in the extra-manifest directory

## secrets

Cluster installation requires access to the following credentials at a minimum:

* BMC/idrac credentials to be used by the installer to control the power state of the baremetal servers
* pull secret defining the credetials for accessing the private image registry

These secrets should be stored in a vault server and retrieved during cluster installation. This means that the presence of a vault server is a pre-requisite for installing the OpenShift cluster via ACM GitOps procedure as captured in this repository. 

If a vault server is not available then the CR(s) created in the `secrets` directory need to be updated to provide the credentials locally. However, this approach will result in pushing those credentials to the GIT server and hence appropriate procedures need to be put in place to protect the data in the GIT server, or the credentials need to be manually created prior to stating the GitOps process in order to avoid pushing them to the GIT server.

