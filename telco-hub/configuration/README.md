
# Automated installation
The full telco hub configuration can be applied using an ArgoCD application pointing to the kustomization.yaml in this directory.

## Pre-requisites
* An OpenShift cluster with the gitops-operator (ArgoCD) installed
  * Note that the reference configuration includes a ClusterRole for ArgoCD which grants the necessary permissions for installing the remainder of the reference. This updates the currently running      ArgoCD application to allow it to complete the full synchronization.
* If ODF will be used in "internal" mode, nodes with available storage for ODF must be labeled
  `cluster.ocs.openshift.io/openshift-storage=`
* All files/directories in this tree are available in a git repository along with any necessary kustomize overlay for your environment.
* Configured and existing Openshift CatalogSources for `redhat-operators-disconnected` and `certified-operators-disconnected`.

## Init phase (prepare ArgoCD)

ArgoCD is one of the main key components of the Telco Hub. At the same time, we can deploy the Telco Hub using ArgoCD (recommended procedure). Therefore, to have a Telco Hub with ArgoCD, first, we have to have ArgoCD to create the Telco Hub. This is the init phase.

In this init phase we will install ArgoCD with the existing `reference-crs` for gitops. But, you could provide ArgoCD differently, or maybe, you already have ArgoCD in your cluster. 

In case you want to proceed with the existing `reference-crs` for gitops (recommended): 

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

Before creating the Telco Hub ArgoCD Application, you have to select the different optional component, and configure all of them. This is done using the different available kustomize patches. 

At this point, in general, you will fork this repo to tune the different kustomize patches and to select the optional components. There exists a `kustomize.yaml` with all the information:

```yaml
---
# kustomization file including different overays over the
# reference crs
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # comment the optional components when not using them
  - reference-crs/optional/lso/
  - reference-crs/optional/odf-internal/
  # everything under required is mandatory
  - reference-crs/required/gitops/
  - reference-crs/required/acm/
  - reference-crs/required/talm/
  # but, include this content if you want to include the argocd
  # configuration and apps for gitops ztp management of cluster
  # installation and configuration
  # - reference-crs/required/gitops/ztp-installation

# following the different overlays to patch
# the different configurations. In case you are not using some of the
# optional components, comment the proper patches
#
patches:
  # if you use LocalStorage operator, edit and configure the patch
  - target:
      group: local.storage.openshift.io
      version: v1
      kind: LocalVolume
      name: local-disks
    path: example-overlays-config/lso/local-storage-disks-patch.yaml
```

### (Optional) Configure the LocalStorage overlay

Edit the file `example-overlays-config/lso/local-storage-disks-patch.yaml` to use the disks you want to be used for the LocalStorage operator. Example:

```
# patching mco StorageClass

- op: replace
  path: /spec/storageConfig/storageClass
  value: "ocs-storagecluster-cephfs" #filesystem StorageClass
```


### Configure the MCO Storage

Edit the file `example-overlays-config/acm/storage-mco-patch.yaml` to select an StorageClass of kind FileSystem. Example:

```yaml
# patching mco StorageClass

- op: replace
  path: /spec/storageConfig/storageClass
  value: "ocs-storagecluster-cephfs" #filesystem StorageClass
```

### Configure AgentServiceConfig options

Edit the file `options-agentserviceconfig-patch.yaml` to configure the different storage classes, for the different services. If connected environment enable removal of the custom registry, and set the RHCOS images to the official repository. Example:

```yaml

```

## Create the `hub-config` ArgoCD Application 

Having ArgoCD ready and the git repository with all the overlays configured. It is time to install the ArgoCD Application that will trigger the deployment of the telco hub. 

You have to edit the gitops patch overlay to configure it properly. By default, it directly points to the upstream repository:

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

Make sure your KUBECONFIG env var is correcty set for your hub cluster, and run the following command:

```
> kustomize build reference-crs/required/gitops/ | oc apply -f -
configmap/argocd-ssh-known-hosts-cm configured
secret/ztp-repo created
appproject.argoproj.io/infra created
application.argoproj.io/hub-config created
```


The ArgoCD application will be created on your cluster. Note that at this point the ArgoCD application is also being managed via gitops and any changes to the application should be done in git as well.



### Expected overlay configuration
The Hub reference configuration needs some environment/cluster
specific content. This is done using kustomize overlay to provide that
content. The following list highlights typical areas where overlay may
be needed:
* ACM
  * Observability secret
  * MultiClusterObservability storage configuration (sizes, StorageClass)
  * AgentServiceConfig -- StorageClass, osImages
  * Provisioning -- disableVirtualMediaTLS if required
* GitOps
  * argocd-application -- Repository access, path, etc
  * argocd TLS certs
* LSO
  * LocalVolume -- StorageClass and devices
* ODF
  * StorageCluster -- storage device set specifications (StorageClass, count, size)
* GitOps ZTP
  * Applications -- Repository access, path, etc
