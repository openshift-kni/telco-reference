## Image-Based Upgrades (IBU)

This directory contains examples of generating resources required for Image Based Upgrades (IBU) utilizing the [Life Cycle Agent operator](https://github.com/openshift-kni/lifecycle-agent). These examples define policies to automate image-based upgrades, ensuring seamless deployment across managed clusters through Gitops.

### Prerequisites

- Advanced Cluster Management (ACM) 2.10+
- Before using the IBU examples, ensure that the following namespaces have been created:
  - `ztp-group`: The ibu policies will be created in this namespace. If you use another name for the `group` namespace, please remember to add the namespace in [ns.yaml](../ns.yaml)
  - `openshift-adp`: The ConfigMap containing the related OpenShift API for Data Protection (OADP) Custom Resources (CRs) will be copied to this namespace on the applicable spoke cluster(s).

### Setup ArgoCD Application

To deploy the IBU examples, use the policies Application in
[telco-ran/configuration/argocd/deployment/policies-app.yaml](../../argocd/deployment/policies-app.yaml),
which syncs `telco-ran/configuration/acmpolicygenerator` (including this
directory when listed in its kustomization). For hub preparation and ArgoCD
setup, see [argocd/README.md](../../argocd/README.md).

Ensure that your Git repository contains a directory structured as follows:

```plaintext
telco-ran/configuration/
├── reference-crs/ibu/
│   ├── ImageBasedUpgrade.yaml
│   ├── PlatformBackupRestore.yaml
│   └── PlatformBackupRestoreLvms.yaml
├── acmpolicygenerator/image-based-upgrades/
│   ├── custom-oadp-workload-crs.yaml
│   ├── acm-pg-ran-ibu-upgrade.yaml
│   └── kustomization.yaml
```

IBU source CRs are also available in the upstream ZTP site-generator image under
`source-crs/ibu`. In this repository they live under
`telco-ran/configuration/reference-crs/ibu/`. The `kustomization.yaml` in this
directory must reference those manifests using the paths shown above.

### Generating the OADP ConfigMap and Policies

To generate the OADP ConfigMap encapsulating the OADP backup and restore CRs for IBU, use the [`configMapGenerator`](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#configmapgenerator) provided by the Kustomize tool with Platform and Application(optional) backup and restore source files defined in it.
As shown in the example below, this will create a Configmap named `oadp-cm` in the namespace `ztp-group` namespace on the hub cluster.

```yaml
configMapGenerator:
  - files:
      - ../../reference-crs/ibu/PlatformBackupRestore.yaml
    # - ../../reference-crs/ibu/PlatformBackupRestoreLvms.yaml
    # - custom-oadp-workload-crs.yaml
    name: oadp-cm
    namespace: ztp-group

generatorOptions:
  disableNameSuffixHash: true
```

- [PlatformBackupRestore.yaml](../../reference-crs/ibu/PlatformBackupRestore.yaml) is provided to backup and restore ACM klusterlet related resources.
- [PlatformBackupRestoreLvms.yaml](../../reference-crs/ibu/PlatformBackupRestoreLvms.yaml)(optional) is provided for use cases when the LVMS is configured in the cluster as the storage solution.
- `custom-oadp-workload-crs.yaml`(optional) defines the OADP backup and restore CRs for the additional workload running on the target cluster. Ensure that the `custom-oadp-workload-crs.yaml` file includes a one-to-one mapping of OADP backup and restore CRs. It's important to note that these CRs can be stored either in separate YAML manifests or consolidated within a single YAML file (as shown below), with each CR section separated by the `---` directive.

```yaml
apiVersion: velero.io/v1
kind: Backup
metadata:
  labels:
    velero.io/storage-location: default
  name: foobar-app
  namespace: openshift-adp
spec:
  includedNamespaces:
    - foobar
  includedNamespaceScopedResources:
    - secrets
    - deployments
    - statefulsets
  excludedClusterScopedResources:
    - persistentVolumes
---
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: foobar-app
  namespace: openshift-adp
  labels:
    velero.io/storage-location: default
  annotations:
    lca.openshift.io/apply-wave: "3"
spec:
  backupName: foobar-app
```

Use the [acm-pg-ran-ibu-upgrade.yaml](./acm-pg-ran-ibu-upgrade.yaml) example using ACM `PolicyGenerator` to create policies for performing IBU, or [pgt-ibu-upgrade.yaml](./pgt-ibu-upgrade.yaml) using legacy `PolicyGenTemplate` (deprecated). Both examples generate the same policies as following:

- group-ibu-oadp-cm-policy: propagate OADP configmap from hub cluster to target spoke clusters in the `openshift-adp` namespace
- group-ibu-prep-stage-policy: to transition ibu to Prep stage
- group-ibu-upgrade-stage-policy: to transition ibu to Upgrade stage
- group-ibu-finalize-stage-policy: to transition ibu to Idle stage
- group-ibu-rollback-stage-policy(optional): to transition ibu to Rollback stage

Add the template to [kustomization.yaml](./kustomization.yaml) file in the `generators` object.

```yaml
generators:
  # Use PolicyGenerator to create oadp cm and ibu policies
  - acm-pg-ran-ibu-upgrade.yaml
# Legacy (deprecated): use PolicyGenTemplate to create oadp cm and ibu policies
# - pgt-ibu-upgrade.yaml
```

When [acm-pg-ran-ibu-upgrade.yaml](./acm-pg-ran-ibu-upgrade.yaml) is used, override the oadp configmap data field with hub template using the Kustomize patches.

```yaml
patches:
  - target:
      group: policy.open-cluster-management.io
      version: v1
      kind: Policy
      name: group-ibu-oadp-cm-policy
    patch: |-
      - op: replace
        path: /spec/policy-templates/0/objectDefinition/spec/object-templates/0/objectDefinition/data
        value: '{{hub copyConfigMapData "ztp-group" "oadp-cm" hub}}'
```

### Enforcing the Policies

To enforce the stage policies for performing IBU, create a ClusterGroupUpgrade (CGU) CR for each stage policy. The `group-ibu-oadp-cm-policy` policy, which distributes the OADP configmap to applicable managed clusters, should be included in the Prep CGU along with `group-ibu-prep-policy`. Since the OADP configmap should be propagated prior to transitioning the IBU stage to `Prep`, it must be the first policy in the Prep CGU.

For more detailed information on using the Life Cycle Agent (LCA) operator, refer to the [docs](https://github.com/openshift-kni/lifecycle-agent/tree/main/docs).
