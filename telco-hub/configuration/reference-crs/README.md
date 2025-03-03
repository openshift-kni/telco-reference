
# Automated installation
The full hub configuration can be applied using an ArgoCD application
pointing to the kustomization.yaml in this directory.

## Pre-requisites
* An OpenShift cluster with the gitops-operator (ArgoCD) installed
* If ODF will be used in "internal" mode, nodes with available storage for ODF must be labeled `cluster.ocs.openshift.io/openshift-storage= `
* All files/directories in this tree are available in a git repository along with any necessary kustomize overlay for your environment.

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
