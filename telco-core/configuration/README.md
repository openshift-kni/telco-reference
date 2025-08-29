# Reference configuration

## Structure

This directory contains four key components of the reference configuration:

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
- The `reference-crs-kube-compare` tree contains the template copy of the
  baseline configuration for use by the
  [cluster-compare tool](https://github.com/openshift/kube-compare).

## Reference CRs

### Policy generation CRs

The reference includes several PolicyGenerator CRs named "core-xxx.yaml" at this
top level. These CRs serve as manifests and customization of the reference
configuration CRs. The PolicyGenerator CR is turned into ACM Policy CRs which
can then be used to configure one or more clusters with the reference
configuration. When these PolicyGenerator CRs and the reference-crs that they
enumerate are stored in a Git repository the [PolicyGenerator
GitOps/ArgoCD](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.14/html/governance/policy-deployment#policy-generator)
plugin will automatically convert them when synchronizing to a hub cluster. The
telco-hub reference in this repository creates a hub cluster with GitOps
operator configuration which supports this methodology. Alternately you can
convert these CRs to Policy locally using the same binary. For example:
`PolicyGenerator core-baseline.yaml`

#### Policy Generators

There are three reference PolicyGenerator CRs.

* `core-baseline` contains fixed required content
* `core-overlay` contains content where updates/patches are expected. This
  reference also contains the optional components
* `core-upgrade` contains policies which can be used to upgrade a cluster from
  the prior release to the current release.
* `core-upgrade-finish` contains policies which release MachineConfigPool worker
  nodes for upgrade. These are typically independent of version and only need to
  be defined once.

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

`<clusterName>` -- Values which are cluster specific. One ConfigMap per cluster
is needed. The ConfigMap name is the cluster name eg cluster-1234

- Current set of keys are fixed values

### Upgrading
The `core-upgrade.yaml` PolicyGenerator generates policies which support an
automated upgrade of the Core cluster. These policies can be used in support of
a single release upgrade or for an EUS-EUS upgrade which involves a double
upgrade. In the case of a double upgrade the worker nodes remain paused while
the control plane is upgraded twice using the `core-upgrade.yaml` policies from
both releases. When both control plane upgrades are complete the worker nodes
are released to upgrade once. Regardless of single or double release upgrade the
sequence for each release upgrade are the same:
 * **Upgrade prep**: Prepare for the upgrade by moving CatalogSource, pausing worker
   MachineConfigPools and any other pre-work. This is the `core-upgrade-prep-##`
   policy in `core-upgrade.yaml`
 * **Upgrade OpenShift**: Upgrade the OpenShift control plane to the desired target
   release. This must be a valid upgrade path and must comply with the k8s
   requirement that you move through y-stream releases sequentially. This is the
   `core-upgrade-ocp-##` policy in `core-upgrade.yaml`
 * **Upgrade OLM day-2**: Upgrade any day-2 OLM operators as needed. Confirm
   compatibility of the Operator version with underlying OpenShift version. This
   is the `core-upgrade-olm-##` policy in `core-upgrade.yaml`
 * **Validation/completion**: Validation checks to ensure upgrade has
   completed. This is the `core-upgrade-validate-##` policy in
   `core-upgrade.yaml`
 * **Release workers**: Allow worker nodes to update. This is only done at the end
   of the second upgrade in two-release upgrade scenarios. This is the
   `core-upgrade-workers-#` policies in `core-upgrade-finish.yaml`

#### Worker Node Upgrade
At the completion of control plane upgrade the completion policies are used to
unpause worker MachineConfigPools (MCP) allowing them to update. This typically
involves cordon/drain and reboot of the nodes. The reference policies here
presume that the cluster and workloads are structured to allow all nodes in an
MCP to be cordoned/drained and rebooted simultaneously. This significantly
accelerates upgrades but requires appropriate cluster and application design. In
specific:
* The worker nodes are partitioned into multiple MCPs in support of upgrades. eg
  10 MCPs each comprising ~10% of the nodes.
* The nodes in each MCP are labeled as a unique
  `topology.kubernetes.io/zone`. ie all nodes in the MCP have the same value for
  this label and nodes in two different MCPs have different values for this
  label. This helps ensure that pod replicas are scheduled to different zones
  (thus different MCPs). When scheduled this way the reboot of an MCP does not
  violate any PodDisruptionBudget for the replicaset -- assuming sufficient
  number of zones and cluster capacity.
* The upgrade policy for MCPs holding nodes which can't be updated
  simultaneously are updated to set maxUnavailable to an appropriate value. For
  example given a single MCP with unique configuration (ie it contains the only
  valid nodes for a class of workload pods) with only 3 nodes. The MCP is
  hosting pods with 3 replicas (one per node). The maxUnavailable for this MCP
  would be set to 1 instead of the 100% in the reference. This ensures nodes are
  updated serially and high availability of the pods in this MCP is maintained.

#### Orchestrating upgrade
With the prep, ocp, olm and completion policies defined the upgrade can be
orchestrated by enforcing those policies in the correct order. This can be done
with the Topology Aware Lifecycle Manager operator. This operator works by
reconciling ClusterGroupUpgrade CRs in which the set of policies, and the order
in which to enforce them, is defined. For a double upgrade scenario which
updates the worker nodes after the second control-plane upgrade the set of CGU
CRs to use would look similar to these:

First control plane upgrade:
```
---
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  name: upgrade-19
  namespace: default
spec:
  actions:
    afterCompletion:
      deleteClusterLabels:
        upgrade-version-4-19: ""
      deleteObjects: true
  clusters:
  - test-cluster
  enable: true
  managedPolicies:
    - core-upgrade-prep-19
    - core-upgrade-ocp-19
    - core-upgrade-olm-19
    - core-upgrade-validate-19
  remediationStrategy:
    maxConcurrency: 1
    timeout: 480
```

Second control plane upgrade:
```
---
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  name: upgrade-20
  namespace: default
spec:
  actions:
    afterCompletion:
      deleteClusterLabels:
        upgrade-version-4-20: ""
      deleteObjects: true
  clusters:
  - test-cluster
  enable: true
  managedPolicies:
    - core-upgrade-prep-20
    - core-upgrade-ocp-20
    - core-upgrade-olm-20
    - core-upgrade-validate-20
  remediationStrategy:
    maxConcurrency: 1
    timeout: 480
  blockingCRs:
  - name: upgrade-19
    namespace: default
```

Release worker nodes:
```
---
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
metadata:
  name: upgrade-finish
  namespace: default
spec:
  clusters:
  - test-cluster
  enable: true
  managedPolicies:
    # These policies unpause the MCP
    - core-upgrade-workers-1
    - core-upgrade-workers-2
    - core-upgrade-workers-3
  remediationStrategy:
    maxConcurrency: 1
    timeout: 480
  blockingCRs:
  - name: upgrade-20
    namespace: default
```


## Contributing

Given that the `reference-crs` and `reference-crs-kube-compare` versions of the
baseline configuration must be kept in sync, there is a github CI check than
enforces this.  Running `make check` in this directory locally is equivalent to
the CI.

If `make check` detects differences, you should take one of the following actions:

- Edit the `reference-crs` CRs or `reference-crs-kube-compare` templates so the
  templates match the corresponding CRs.
- For missing files, add the missing file to either the `reference-crs`
  directory, or the `reference-crs-kube-compare` directory and metadata.yaml

  - Alternatively, add the filename to the
    `reference-crs-kube-compare/compare_ignore`, but only if the CR in
    `reference-crs` should not be checked by the cluster-compare tool.
