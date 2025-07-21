
# Automated installation
The full telco hub configuration can be applied using an ArgoCD application pointing to the kustomization.yaml in this directory.

## Pre-requisites
* An OpenShift cluster with the gitops-operator (ArgoCD) installed
  * Note that the reference configuration includes a ClusterRole for ArgoCD which grants the necessary permissions for installing the remainder of the reference. This updates the currently running ArgoCD application to allow it to complete the full synchronization.
* If ODF will be used in "internal" mode, nodes with available storage for ODF must be labeled
  `cluster.ocs.openshift.io/openshift-storage=`
* All files/directories in this tree are available in a git repository along with any necessary kustomize overlay for your environment.
* Configured and existing Openshift CatalogSources for `redhat-operators-disconnected` and `certified-operators-disconnected`.

## Init phase (install ArgoCD or Openshift GitOps)

This phase can be considered optional, in case you already have ArgoCD or Openshift GitOps running on your cluster.

ArgoCD is one of the main key components of the Telco Hub, because is in charge of managing deployment and configuration of the infrastructure managed by the Telco Hub, using a GitOps methodology. But, at the same time, we can deploy the Telco Hub using ArgoCD (recommended procedure). Therefore, to have a Telco Hub with ArgoCD, first, we have to have ArgoCD to create the Telco Hub. This is the init phase, and it is optional if you already fulfilled this requirement.

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

Before creating the Telco Hub ArgoCD Application, you have to select the different optional component, and configure all of them.

At this point, you will need to fork this repo to tune the different kustomize patches and to select the optional components. There exists a root `kustomize.yaml` with all the information:

```yaml
# kustomization file including different overays over the
# reference crs
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # if you use LocalStorage operator, edit and configure the patch
  - example-overlays-config/lso/

  # if you use ODF, edit and configure storage settings
  - example-overlays-config/odf/

  # other not optional overlays
  - example-overlays-config/gitops/
  - example-overlays-config/acm/

  # mandatory resources not managed by any overlay
  - reference-crs/required/talm/

  # include this content if you want to include the argocd
  # configuration and apps for gitops ztp management of cluster
  # installation and configuration
  # - reference-crs/required/gitops/ztp-installation
```
Comment/uncomment the different optional components. For any of these directories, there could be optional configurations that needs to be set depending on your needs. The following sections describe the different options to configure.

### (Optional) Configure the LocalStorage 

Edit the file `example-overlays-config/lso/local-storage-disks-patch.yaml` to use the disks you want to be used for the LocalStorage operator. Example:

```
# patching ODF StorageCluster

- op: replace
  path: /spec/storageDeviceSets/0/dataPVCTemplate/spec/resources/requests/storage
  value: "600Gi"

- op: replace
  path: /spec/storageDeviceSets/0/dataPVCTemplate/spec/storageClassName
  value: "local-sc"
```

### (Optional) Configure ODF 
Edit the file `example-overlays-config/odf/options-storage-cluster.yaml` to configure the storage backend for ODF. Example:

```yaml
# patching ODF StorageCluster

- op: replace
  path: /spec/storageDeviceSets/0/dataPVCTemplate/spec/resources/requests
  value: "400Gi"

- op: replace
  path: /spec/storageDeviceSets/0/dataPVCTemplate/spec/resources/storageClassName
  value: "local-sc"
```

### Configure the MultiClusterObservability Storage

Edit the file `example-overlays-config/acm/storage-mco-patch.yaml` to select an StorageClass of kind FileSystem. Example:

```yaml
# patching mco StorageClass

- op: replace
  path: /spec/storageConfig/storageClass
  value: "ocs-storagecluster-cephfs" # filesystem StorageClass
```

### Configure AgentServiceConfig options

Edit the file `options-agentserviceconfig-patch.yaml` to configure the different storage classes, for the different services. Set the RHCOS images to the proper repository, in case of disconnected, the one you are providing, in case of connected, you can use the Red Hat official ones. Also, if connected environment enable removal of the custom registry, because the spokes dont need to be feed with an internal registry.
```yaml
# patching mco StorageClass

- op: replace
  path: /spec/databaseStorage/storageClassName
  value: "ocs-storagecluster-cephfs"  # filesystem StorageClass

- op: replace
  path: /spec/filesystemStorage/storageClassName
  value: "ocs-storagecluster-cephfs"  # filesystem StorageClass

- op: replace
  path: /spec/imageStorage/storageClassName
  value: "ocs-storagecluster-cephfs"  # filesystem StorageClass

  # Configure the osImages urls.
  # When disconnected, the urls should point to a mirrored registry.
- op: replace
  path: "/spec/osImages"
  value:
    - cpuArchitecture: x86_64
      openshiftVersion: "4.16"
      rootFSUrl: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.16/latest/rhcos-live-rootfs.x86_64.img
      url: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.16/latest/rhcos-live.x86_64.iso
      version: 416.94.202411261619-0
    - cpuArchitecture: "x86_64"
      openshiftVersion: "4.17"
      rootFSUrl: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.17/latest/rhcos-live-rootfs.x86_64.img
      url: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.17/latest/rhcos-live.x86_64.iso
      version: "417.94.202409121747-0"
    - cpuArchitecture: x86_64
      openshiftVersion: "4.18"
      rootFSUrl: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.18/latest/rhcos-live-rootfs.x86_64.img
      url: https://mirror.example.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.18/latest/rhcos-live.x86_64.iso
      version: 418.94.202502100215-0

# when disconnected, the spoke clusters will need to use also a mirrored registry. That could be configured here:
# https://issues.redhat.com/browse/CNF-17835

# In case of connected enviroment we dont need neither to configure
# nor use an internal registry on the spokes. So, uncomment below to remove it:
# - op: remove
#   path: /spec/mirrorRegistryRef
```

### Configure the `hub-config` ArgoCD Application

You have to edit the gitops patch overlay (`example-overlays-config/gitops/init-argocd-app.yaml`) to configure it properly. By default, it directly points to the upstream repository:

```yaml
> cat required/gitops/overlays/init_installation_app.yaml
- op: replace
  path: "/spec/source"
  value:
    - repoURL: "telco-hub/configuration/reference-crs"
      path: "https://github.com/openshift-kni/telco-reference.git"
      targetRevision: "main"
```

Make any necessary change. In general, you will point to the forked repository where you have been tuning your own overlay layer. Example:

```yaml
- op: replace
  path: "/spec/source"
  value:
    - repoURL: "telco-hub/configuration/reference-crs"
      path: "https://github.com/jgato/telco-reference.git"
      targetRevision: "improve-automatization-overlays"
```

## Create the `hub-config` ArgoCD Application

Having ArgoCD ready and the git repository with all the overlays configured. It is time to install the ArgoCD Application that will trigger the deployment of the telco hub.

```bash
> kustomize build example-overlays-config/gitops/ | oc apply -f -
configmap/argocd-ssh-known-hosts-cm configured
secret/ztp-repo created
appproject.argoproj.io/infra created
application.argoproj.io/hub-config created
```


The ArgoCD application will be created on your cluster and will start installing and configuring all the needed Telco Hub components. Note that at this point the ArgoCD application is also being managed via gitops and any changes to the application should be done in git as well.
