# Ability to include CRs at install time

Assisted Installer allows CRs to be applied to SNOs at install time. The applied CRs may include Machine Configs from RAN Far Edge (e.g to enable Workload Partitioning) or CRs defined by the users themselves. More details [here](https://github.com/openshift/assisted-service/blob/c183b5182bfed15e42745e9f7fd3bd4f21184bde/docs/hive-integration/README.md#creating-additional-manifests).

With this feature, via ClusterInstance, users can now have control over this process and can inject manifets during installation by creating a configMap in a Kustomization file and later reference back the configMap name to `.spec.extraManifestsRefs` in ClusterInstance.

* An example of a kustomization file, where the manifests are included in a configMap using configMapGenerator 

  ```yaml
  configMapGenerator:
  - files:
    - extra-manifest/01-container-mount-ns-and-kubelet-conf-master.yaml
    - extra-manifest/01-container-mount-ns-and-kubelet-conf-worker.yaml
    - extra-manifest/01-disk-encryption-pcr-rebind-master.yaml
    - extra-manifest/01-disk-encryption-pcr-rebind-worker.yaml
    - extra-manifest/03-sctp-machine-config-master.yaml
    - extra-manifest/03-sctp-machine-config-worker.yaml
    - extra-manifest/06-kdump-master.yaml
    - extra-manifest/06-kdump-worker.yaml
    - extra-manifest/07-sriov-related-kernel-args-master.yaml
    - extra-manifest/07-sriov-related-kernel-args-worker.yaml
    - extra-manifest/08-set-rcu-normal-master.yaml
    - extra-manifest/08-set-rcu-normal-worker.yaml
    - extra-manifest/09-openshift-marketplace-ns.yaml
    - extra-manifest/99-sync-time-once-master.yaml
    - extra-manifest/99-sync-time-once-worker.yaml
    - extra-manifest/enable-crun-master.yaml
    - extra-manifest/enable-crun-worker.yaml
    name: sno-ran-du-extra-manifest-1
    namespace: <namespace>
  generatorOptions:
    disableNameSuffixHash: true
  ```


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

