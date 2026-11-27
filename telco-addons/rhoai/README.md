# OpenShift AI policy

This directory contains a policy generator used to deploy OpenShift AI on an existing OpenShift cluster.

The current version deploys OpenShift AI with support for basic inference via KServe using a single deployment.

## Requirements

The pre-requisites for OpenShift AI deployment are detailed in the [official documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#component_requirements). Make sure all required operators are installed before deploying OpenShift AI.

## Disconnected environments

When deploying on a disconnected environment, you will need to mirror the operator images for OpenShift AI, as well as some additional images required during runtime. Use the [ImageSetConfiguration file](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper/blob/main/rhoai-3.5.4-imagesetconfig.yaml) from the disconnected installer helper repository as a reference to build the mirroring configuration for your environment.

If AI pipelines or workbenches will be used. the Kueue and JobSet operators will need to be mirrored, too. Refer to the [ImageSetConfiguration file](disconnected-mirror/isc-kueue-jobset.yaml) located in the `disconnected-mirror` directory to build the mirroring configuration.

## Usage

The `argocd/` directory contains an example argocd `AppProject` and `Application` resource you can use to deploy OpenShift AI as a separate day-2 operation. Make sure you adapt the `repoURL` and `path` values for the argocd application to point to your Git repository structure.

Two different `PolicyGenerator` resources are provided, depending on the required use case:

- `rhoai-inferencing.yaml` for basic inferencing using KServe.
- `rhoai-workbench-pipelines.yaml` for pipelines or workbenches usage.

Edit the `kustomization.yaml` file in this directory to select the required deployment type.

The `PolicyGenerator` resource includes a `placement` section, used to match labels in the target clusters. Make sure the target `ManagedCluster` resources contain the required labels to ensure the policies are assigned correctly.


