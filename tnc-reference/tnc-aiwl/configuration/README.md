# TNC configuration

## Structure

This directory contains five key components of the TNC configuration:

- The `reference-crs` tree contains the baseline configuration CRs which make
  up the RDS Core reference configuration. These are further separated into
  optional vs required configuration.
- The `other-crs` tree contains the configuration that is added by TNC 
  to augment the baseline RDS configuration. These are further separated into 
  optional vs required configuration.
- The yaml files in this top level support application and ongoing management
  of the reference configuration using Advanced Cluster Management (ACM)
  Policy. These yaml serve as manifests which define how CRs from the
  reference-crs tree are grouped into policies and apply certain use case
  specific patches to the policy wrapped CRs.
- The `template-values` directory holds ConfigMaps which provide values used in
  the ACM Policies. See the "Templating" section below for more details.
- (Future) The `tnc-crs-kube-compare` tree contains the template copy of the
  TNC configuration for use by the
  [cluster-compare tool](https://github.com/openshift/kube-compare).

## Reference CRs

### Policy generation CRs

The repository includes several PolicyGenerator CRs named "core-xxx.yaml" and `cwl-xxx.yaml` at this
top level. These CRs serve as manifests and customization of the `reference` and `other`
configuration CRs. The PolicyGenerator CR is turned into ACM Policy CRs which
can then be used to configure one or more clusters with the sub-architecture
configuration. When these PolicyGenerator CRs and the reference-crs that they
enumerate are stored in a Git repository the [PolicyGenerator
GitOps/ArgoCD](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/governance/policy-deployment#policy-generator)
plugin will automatically convert them when synchronizing to a hub cluster.

#### Policy Generators

The repository provides the following policy generators:

* `aiwl-baseline` contains baseline configuration for TNC AIWL
* `aiwl-odf-internal` configures the OpenShift cluster to use ODF in internal mode
* `aiwl-odf-external` configures the OpenShift cluster to use ODF in external mode
* `aiwl-kafka` configures OpenShift logs and metrics forwarding to kafka
* `aiwl-auth-idm.yaml` contains policies to configure OAUTH to use LDAP for authentication
* `core-finish` contains policies which release/un-pause MachineConfigPool worker
  nodes. These are typically independent of version and only need to
  be defined once.

These policy generators use labels to apply the policies to the appropriate clusters.
Apply the following labels to the clusters in order to configure them with the appropriate policies:

- aiwl: "true"        - To apply the TNC CWL policies
- tnc-ver: "tnc6.1"  - To pick TNC 6.1 policies
- Pick one the following:
  - odf-ext: "true"    - To configure ODF in external mode
  - odf-int: "true"    - To configure ODF in internal mode
- kafka: "true"       - To configure logs and metrics to be sent to kafka
- idm: "true"       - To configure OAUTH for LDAP authentication

Other custom content can be added through additional PolicyGenerator CRs.


#### Templating

These PolicyGenerator CRs create Policies which include ACM hub side
templates. These templates will pull values from 3 configmaps:

`template-values/hw-types` -- Hardware dependent data.

- Current set of keys are fixed valued based on hardware profiles (mcp names)
  as defined in core-overlay.

`template-values/regional` -- Values which may depend on the region/zone where a
cluster is deployed.

- keyed by a "region" label on the ManagedCluster
- eg %s-log-url -- a cluster labeled 'region: abcd' would use abcd-log-url
   from regional configmap

`template-values/<clusterName>` -- Values which are cluster specific. One ConfigMap per cluster
is needed. The ConfigMap name is the cluster name eg cluster-1234


