# Reference configuration

## Structure
This directory contains three key components of the reference configuration
 - The `reference-crs` tree contains the baseline configuration CRs which make
   up the Core reference configuration. These are further separated into
   optional vs required configuration.
 - The yaml files in this top level support application and ongoing management
   of the reference configuration using Advanced Cluster Management (ACM)
   Policy. These yaml serve as manifests which define how CRs from the
   reference-crs tree are grouped into policies and apply certain use case
   specific patches to the policy wrapped CRs.
 - The `template-values` directory holds ConfigMaps which provide values used in
   the ACM Policies. See the "Templating" section below for more details.

## Reference CRs

## Policy generation CRs
### Policy Generators
There are three reference PolicyGenerator CRs.
 - `core-baseline` contains fixed required content
 - `core-overlay` contains content where updates/patches are expected. This
   reference also contains the optional components
 - `core-upgrade` contains policies which can be used to upgrade a cluster from
   the prior release to the current release.

Other custom content can be added through additional PolicyGenerator CRs.

### Templating
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

`<clusterName>` -- Values which are cluster specific. One ConfigMap per cluster
is needed. The ConfigMap name is the cluster name eg cluster-1234
 - Current set of keys are fixed values
