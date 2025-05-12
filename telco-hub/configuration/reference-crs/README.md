
# Automated installation
The full hub configuration can be applied using an ArgoCD application
pointing to the kustomization.yaml in this directory.

## Pre-requisites
* An OpenShift cluster with the gitops-operator (ArgoCD) installed
  * Note that the reference configuration includes a ClusterRole for
    ArgoCD which grants the necessary permissions for installing the
    remainder of the reference. This updates the currently running
    ArgoCD application to allow it to complete the full
    synchronization.
* If ODF will be used in "internal" mode, nodes with available storage
  for ODF must be labeled
  `cluster.ocs.openshift.io/openshift-storage=`
* All files/directories in this tree are available in a git repository
  along with any necessary kustomize overlay for your environment.

## Installation
Prime the ArgoCD application to start the automated installation of
the remaining components and configuration. It is likely you have an
overlay for the gitops directory to provide the correct URL of your
repository. If so, this `kustomize build` should point to your overlay
which includes the reference-crs/gitops directory as the base. Make
sure your KUBECONFIG env var is correcty set for your hub cluster and
run this command:
`kustomize build reference-crs/required/gitops | oc apply -f -`

The ArgoCD application will be created on your cluster and start to
synchronize the rest of the configuration. Note that at this point the
ArgoCD application is also being managed via gitops and any changes to
the application should be done in git as well.

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
