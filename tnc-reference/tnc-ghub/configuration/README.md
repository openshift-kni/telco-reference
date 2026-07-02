
# Automated installation
The full TNC Global Management (g-mgmt) cluster configuration can be applied using an ArgoCD application pointing to the kustomization.yaml in this directory.

## Pre-requisites
* An OpenShift cluster with the gitops-operator (ArgoCD) installed
  * Note that the reference configuration includes a ClusterRole for ArgoCD which grants the necessary permissions for installing the remainder of the reference. This updates the currently running ArgoCD application to allow it to complete the full synchronization.
* If ODF will be used in "internal" mode, nodes with available storage for ODF must be labeled
  `cluster.ocs.openshift.io/openshift-storage=`
* All files/directories in this tree are available in a git repository along with any necessary kustomize overlay for your environment.
* Configured and existing Openshift CatalogSources for `redhat-operators-disconnected` and `certified-operators-disconnected`.

## Init phase (install ArgoCD or Openshift GitOps)

This phase can be considered optional, in case you already have ArgoCD or Openshift GitOps running on your cluster.

ArgoCD is one of the main key components of the g-mgmt cluster, because is in charge of managing deployment and configuration of the infrastructure managed by the g-mgmt cluster, using a GitOps methodology. But, at the same time, we can deploy the g-mgmt cluster using ArgoCD (recommended procedure). Therefore, to have a g-mgmt cluster with ArgoCD, first, we have to have ArgoCD to create the g-mgmt cluster. This is the init phase, and it is optional if you already fulfilled this requirement.

In this init phase we can install ArgoCD with the existing `reference-crs` for GitOps, basically using the Openshift GitOps operator. In case you want to proceed the installation with the existing `reference-crs` for GitOps: 

```bash
oc apply -f reference-crs/required/gitops/clusterrole.yaml \
  -f reference-crs/required/gitops/clusterrolebinding.yaml \
  -f reference-crs/required/gitops/gitopsNS.yaml \
  -f reference-crs/required/gitops/gitopsOperatorGroup.yaml \
  -f reference-crs/required/gitops/gitopsSubscription.yaml
```

Wait the operator to be installed:

```bash
> oc -n openshift-gitops-operator get subscriptions.operators.coreos.com openshift-gitops-operator -o jsonpath='{.status.state}'

AtLatestKnown

> oc -n openshift-gitops-operator get pod
NAME                                                         READY   STATUS    RESTARTS   AGE
openshift-gitops-operator-controller-manager-d97fddc-9zmrn   2/2     Running   0          21m

> oc -n openshift-gitops get pod
NAME                                                          READY   STATUS    RESTARTS   AGE
cluster-7b65f74f8f-sbx24                                      1/1     Running   0          37s
gitops-plugin-7d8b6d777b-5npgj                                1/1     Running   0          37s
kam-7bc6f69fcd-jrtgv                                          1/1     Running   0          37s
openshift-gitops-application-controller-0                     1/1     Running   0          35s
openshift-gitops-applicationset-controller-5cddb476fc-q5shw   1/1     Running   0          35s
openshift-gitops-dex-server-954f978c9-2lp44                   1/1     Running   0          35s
openshift-gitops-redis-7ff87f9b48-8ld9x                       1/1     Running   0          35s
openshift-gitops-repo-server-6ccffb9695-pc8bj                 1/1     Running   0          35s
openshift-gitops-server-845d6798-9c5tv                        1/1     Running   0          35s
```

## Tune your own overlay layer

Before creating the ArgoCD Application, you have to select the different optional component, and configure all of them.

At this point, you will need to fork this repo to tune the different kustomize patches and to select the optional components. There exists a root `kustomize.yaml` with all the information. Comment/uncomment the different optional components. For any of these directories, there could be optional configurations that needs to be set depending on your needs. The following sections describe the different options to configure.

### (Optional) Configure the LocalStorage (LSO)

Edit the file `overlays/lso/local-storage-disks-patch.yaml` to use the disks you want to be used for the LocalStorage operator. Example:

```
- op: replace
  path: "/spec/storageClassDevices/0/devicePaths"
  value:  # add devices to be used by local storage operator
    - /dev/nvme1n1
```

### (Optional) Configure ODF 

Edit the file `overlays/odf/options-storage-cluster.yaml` to configure the storage backend for ODF. Example:

```yaml
# patching ODF StorageCluster

- op: replace
  path: /spec/storageDeviceSets/0/dataPVCTemplate/spec/resources/requests
  value: "400Gi"

- op: replace
  path: /spec/storageDeviceSets/0/dataPVCTemplate/spec/resources/storageClassName
  value: "local-sc"
```

Edit the file `overlays/odf/OdfDefaultStorageClass-patch.yaml` to set the appropriate default storage class (ODF vs. LVMS):

````yaml
# patching ODF default storage class

- op: replace
  path: /metadata/name
  value: ocs-storagecluster-ceph-rbd
````

### (Optional) Configure LVMS

Edit the file `overlays/lvms/lvm-cluster-disks-patch.yaml` to configure the disk to be used by LVMS. Example:

```yaml
- op: replace
  path: "/spec/storage/deviceClasses/0/deviceSelector/paths"
  value:  # add devices to be used by LVMS  operator
    - /dev/disk/by-path/pci-0000:3f:00.0-scsi-0:0:3:0
````

### Configure the MultiClusterObservability Storage

Edit the file `overlays/acm/storage-mco-patch.yaml` to select an StorageClass of kind FileSystem. Example:

```yaml
# patching mco StorageClass

- op: replace
  path: /spec/storageConfig/storageClass
  value: "ocs-storagecluster-cephfs" # filesystem StorageClass
```

### Configure AgentServiceConfig options

Edit the file `overlays/odf/options-agentserviceconfig-patch.yaml` to configure the different storage classes, for the different services. Set the RHCOS images to the proper repository, in case of disconnected, the one you are providing, in case of connected, you can use the Red Hat official ones. Also, if connected environment enable removal of the custom registry, because the spokes dont need to be feed with an internal registry.
```yaml
# patching mco StorageClass

- op: replace
  path: /spec/databaseStorage/storageClassName
  # LVM Storage configures the name of the storage class and volume snapshot class in the format lvms-<device_class_name>, where, <device_class_name> is the value of the deviceClasses.name field in the LVMCluster CR. For example, if the deviceClasses.name field is set to vg100, the name of the storage class and volume snapshot class is lvms-vg10.
  value: "ocs-storagecluster-cephfs"  # filesystem StorageClass
  #value: "lvms-vg10"

- op: replace
  path: /spec/filesystemStorage/storageClassName
  value: "ocs-storagecluster-cephfs"  # filesystem StorageClass
  #value: "lvms-vg10"

- op: replace
  path: /spec/imageStorage/storageClassName
  value: "ocs-storagecluster-cephfs"  # filesystem StorageClass
  #value: "lvms-vg10"

  # Configure the osImages urls.
  # When disconnected, the urls should point to a mirrored registry.
- op: replace
  path: "/spec/osImages"
  value:
    - cpuArchitecture: x86_64
      openshiftVersion: "4.18"
      rootFSUrl: http://192.168.22.4/rhcos-live-rootfs.x86_64.img
      url: http://192.168.22.4/rhcos-live.x86_64.iso
      version: 418.94.202501221327-0
    - cpuArchitecture: x86_64
      openshiftVersion: "4.20"
      rootFSUrl: http://192.168.22.4/rhcos-4.20.13-x86_64-live-rootfs.x86_64.img
      url: http://192.168.22.4/rhcos-4.20.13-x86_64-live-iso.x86_64.iso
      version: 9.6.20260112-0

# when disconnected, the spoke clusters will need to use also a mirrored registry. That could be configured here:
# https://issues.redhat.com/browse/CNF-17835

# In case of connected enviroment we dont need neither to configure
# nor use an internal registry on the spokes. So, uncomment below to remove it:
# - op: remove
#   path: /spec/mirrorRegistryRef
```

### Disable ACM Observability for SNO deployments

Since MGMT cluster deployments on SNO don't have object storage, we need to disable ACM observability for the case of SNO MGMT cluster. Edit the file `overlays/acm/kustomization.yaml` and uncomment all the lines that delete the different MCO related CRs.

### Configure the `hub-config` ArgoCD Application

You have to edit the gitops patch overlay (`overlays/gitops/init-argocd-app.yaml`) to configure it properly so that it points to your forked repo:

```yaml
- op: replace
  path: "/spec/source"
  value:
    - repoURL: "tnc-reference/tnc-mgmt/configuration"
      path: "https://github.com/openshift-kni/telco-reference.git"
      targetRevision: "tnc6.1-release-4.20"
```

### Provide the GIT repo credentials for the local cluster configuration

Edit the file `overlays/gitops/ztp-repo-secret-patch.yaml` and provide the URL, username and password for accessing the GIT repo.

### Configure the `cluster` ArgoCD Application for ZTP deployment of workload clusters

You have to edit the gitops-ztp patch overlay (`overlays/gitops-ztp/clusters-app-patch.yaml`) to configure it properly. It should point to the GIT repo that has the spoke clusters:

```yaml
- op: replace
  path: "/spec/source"
  value:
    - repoURL: "tnc-reference/tnc-cwl/install"
      path: "https://github.com/openshift-kni/telco-reference.git"
      targetRevision: "tnc6.1-release-4.20"
```

### Configure the `policies` ArgoCD Application for ZTP configuration of workload clusters

You have to edit the gitops-ztp patch overlay (`overlays/gitops-ztp/policies-app-patch.yaml`) to configure it properly. It should point to the GIT repo that has the spoke clusters:

```yaml
- op: replace
  path: "/spec/source"
  value:
    - repoURL: "tnc-reference/tnc-cwl/configuration"
      path: "https://github.com/openshift-kni/telco-reference.git"
      targetRevision: "tnc6.1-release-4.20"
````

### Provide the GIT repo credentials for the workload cluster ZTP

Edit the file `overlays/gitops-ztp/ztp-repo-workload-secret-patch.yaml` and provide the URL, username and password for accessing the GIT repo.

### Update registry mirroring configuration

Edit the different files in the `overlays/registry` firectory to provide the appropriate catalog source and mirror registry values.

### Provide Vault CA Certificate

Edit the file `overlays/vault/VaultCertificate-ca-patch.yaml` and provide the CA certificate for the external vault.

## Create the `hub-config` ArgoCD Application

Having ArgoCD ready and the git repository with all the overlays configured. It is time to install the ArgoCD Application that will trigger the deployment of the telco hub.

```bash
> kustomize build overlays/gitops/ | oc apply -f -
configmap/argocd-ssh-known-hosts-cm configured
secret/ztp-repo created
appproject.argoproj.io/infra created
application.argoproj.io/hub-config created
```

The ArgoCD application will be created on your cluster and will start installing and configuring all the needed g-mgmt cluster components. Note that at this point the ArgoCD application is also being managed via gitops and any changes to the application should be done in git as well.

