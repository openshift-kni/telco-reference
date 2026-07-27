# Ability to include CRs at install time

Assisted Installer allows CRs to be applied to SNOs at install time. The applied CRs may include Machine Configs from RAN Far Edge (e.g to enable Workload Partitioning) or CRs defined by the users themselves. More details [here](https://github.com/openshift/assisted-service/blob/c183b5182bfed15e42745e9f7fd3bd4f21184bde/docs/hive-integration/README.md#creating-additional-manifests).

With this feature, via ClusterInstance, users can now have control over this process and can inject manifets during installation by creating a configMap in a Kustomization file and later reference back the configMap name to `.spec.extraManifestsRefs` in ClusterInstance.

Reference install manifests live under `telco-ran/install/extra-manifests/`. Optional manifests such as `enable-crun-*.yaml` live under `telco-ran/install/custom-manifests/` and must not be listed in PolicyGenerator CRs; the Hub extra-manifests policy monitors install-time MachineConfigs at day-N.

* An example kustomization (`telco-ran/install/kustomization.yaml`) builds a ConfigMap from the reference manifests:

  ```yaml
  configMapGenerator:
  - files:
    - extra-manifests/01-container-mount-ns-and-kubelet-conf-master.yaml
    - extra-manifests/01-container-mount-ns-and-kubelet-conf-worker.yaml
    - extra-manifests/01-disk-encryption-pcr-rebind-master.yaml
    - extra-manifests/01-disk-encryption-pcr-rebind-worker.yaml
    - extra-manifests/03-sctp-machine-config-master.yaml
    - extra-manifests/03-sctp-machine-config-worker.yaml
    - extra-manifests/06-kdump-master.yaml
    - extra-manifests/06-kdump-worker.yaml
    - extra-manifests/07-sriov-related-kernel-args-master.yaml
    - extra-manifests/07-sriov-related-kernel-args-worker.yaml
    - extra-manifests/08-set-rcu-normal-master.yaml
    - extra-manifests/08-set-rcu-normal-worker.yaml
    - extra-manifests/09-openshift-marketplace-ns.yaml
    - extra-manifests/10-rename-gnrd-interfaces-master.yaml
    - extra-manifests/10-rename-gnrd-interfaces-worker.yaml
    - extra-manifests/99-sync-time-once-master.yaml
    - extra-manifests/99-sync-time-once-worker.yaml
    name: ran-extra-manifests-configmap
    namespace: <namespace>
  generatorOptions:
    disableNameSuffixHash: true
  ```

  To include crun at install time, add `custom-manifests/enable-crun-master.yaml` and
  `custom-manifests/enable-crun-worker.yaml` to a separate ConfigMap referenced from
  `ClusterInstance.spec.extraManifestsRefs`.


* A ClusterInstance example to reference back the configMap

  ```yaml
  apiVersion: siteconfig.open-cluster-management.io/v1alpha1
  kind: ClusterInstance
  metadata:
    name: cnfdg12
    namespace: cnfdg12
  spec:
    ...
    extraManifestsRefs:
    - name: sno-ran-du-extra-manifest-1
  ```

