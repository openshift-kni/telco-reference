# OpenShift installation with the Agent-based Installer

1. [Download the Agent-based Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installing-with-agent-basic#installing-ocp-agent-retrieve_installing-with-agent-basic)
2. Create a new directory `ocp`, copy the [install-config.yaml](install-config.yaml) and the [agent-config.yaml](agent-config.yaml) files and modify them to fit your environment.
   Read the inline comments for suggestions on which fields should be modified and how.
3. Also copy the `openshift` directory and all its files to the `ocp` directory. Edit the `catalogSource-disconnected.yaml` and `idms.yaml` files to reflect the correct URL for the private registry. Or copy updated versions of those files from the working directory that was created by `oc-mirror` while mirroring the images to the local registry: `oc-mirror-workspace/working-dir/cluster-resource/`.
4. Generate the ABI ISO image with the following command:

   `openshift-install --dir ocp agent create image`
5. Load the generated ISO into each node's local disk and proceed with the OpenShift installation. To monitor the process use:

   `openshift-install --dir ocp agent wait-for bootstrap-complete --log-level=info`
   `openshift-install --dir ocp agent wait-for install-complete`
6. Verify that the installation has completed successfully with:

   `export KUBECONFIG=ocp/auth/kubeconfig`

   `oc get nodes` (check that all the nodes are ready)

   `oc get clusterversion` (check that the status is “Cluster version is <4.x.x>”)

   `oc get clusteroperators` (check that all the operators have been installed)

For more information see [Installing an OpenShit cluster with the Agent-based Installer](https://docs.openshift.com/container-platform/4.20/installing/installing_with_agent_based_installer/installing-with-agent-based-installer.html).

