# Telco Hub Cluster Setup

The goal of this document is to provide a step-by-step guide on how to install and configure a Hub cluster that follows the
specifications and recommendations of the [Telco Hub Cluster RDS](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/scalability_and_performance/telco-hub-ref-design-specs). Starting from a basic OpenShift cluster,
the different operators that make up a Hub cluster will be installed, all in a disconnected environment.

The Yaml manifests used to install the OpenShift cluster and the required mirror registry can be found in the [install](install) folder
whereas the reference CRs for the day-2 operators are stored in the [configuration](configuration) folder. These manifests can be
modified to suit your specific environment (i.e. ssh keys, pull-secret, resources config, etc.) prior to being applied to your cluster. In the recommended automated method this is done using kustomize.

## Pre-requisites

There are two components required prior to start the configuration of a Hub cluster, a basic OpenShift cluster and a mirror registry already loaded with
all the container images that will be used for the OpenShift and the day-2 operators installation.

### OpenShift cluster

The Telco Hub Cluster RDS recommends using the Agent-based Installer (ABI) to install the OpenShift cluster although any other installation method
is acceptable as long as they reach the same end result. The instructions below show the OpenShift installation using the ABI method.

[OpenShift installation with the Agent-based Installer](install/openshift/README.md)

### Mirror registry

The instructions that follow consider a partially-disconnected environment. In this kind of environment there is a host that has
Internet connectivity but the OCP nodes of the Hub cluster are disconnected. This scenario has the advantage that it allows to create and
populate the mirror registry directly using the public repositories while proceeding with the Hub cluster installation as if it was fully-disconnected.
For a fully disconnected environment a few additional step are required (see [Mirroring an image set in a fully disconnected environment](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/disconnected_environments/index#mirroring-image-set-full)).

[Mirror registry setup](install/mirror-registry/README.md)

## Automated installation
This is the recommended approach to install the Hub cluster. The automation uses the GitOps operator to deploy and configure all the required components. See [Automated installation](configuration/README.md) for more information.

## Manual configuration of Hub components

The following instructions cover the installation and configuration of the day-2 operators required to turn the basic OpenShift cluster into a Hub cluster.
They should be installed in the order presented here to ensure that the resource dependencies are properly resolved.

**IMPORTANT:** Do not forget to modify the reference CRs to match your environment and needs.

### Required operators

#### [GITOPS](configuration/reference-crs/required/gitops/readme.md)

#### [LSO](configuration/reference-crs/optional/lso/README.md)

#### [ODF](configuration/reference-crs/optional/odf-internal/README.md)

#### [ACM](configuration/reference-crs/required/acm/readme.md)


### Optional configuration

#### Backup and recovery

[Backup and recovery process](configuration/reference-crs/optional/backup-recovery/README.md)

