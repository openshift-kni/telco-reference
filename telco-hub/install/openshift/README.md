# OpenShift installation with the Agent-based Installer

1. [Download the Agent-based Installer](https://docs.openshift.com/container-platform/4.18/installing/installing_with_agent_based_installer/installing-with-agent-based-installer.html#installing-ocp-agent-retrieve_installing-with-agent-based-installer)
2. Create a new directory `ocp`, copy the [install-config.yaml](install-config.yaml) and the [agent-config.yaml](agent-config.yaml) files and modify them to fit your environment.
   Read the inline comments for suggestions on which fields should be modified and how.
3. Generate the ABI ISO image with the following command:

   `openshift-install --dir ocp agent create image`
4. Load the generated ISO into each node's local disk and proceed with the OpenShift installation. To monitor the process use:

   `openshift-install --dir ocp agent wait-for bootstrap-complete --log-level=info`
   `openshift-install --dir ocp agent wait-for install-complete`
5. Verify that the installation has completed successfully with:

   `oc get nodes` (check that all the nodes are ready)

   `oc get clusterversion` (check that the status is “Cluster version is <4.x.x>”)

   `oc get clusteroperators` (check that all the operators have been installed)
6. Disable the default OperatorHub catalog sources:

   `oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'`
7. Configure the OpenShift cluster to use the mirror registry’s catalog sources:

   `oc apply -f oc-mirror-workspace/working-dir/cluster-resource`

8. Verify that the resources are properly installed:

   `oc get imagedigestmirrorset`
   `oc get imagetagmirrorset`
   `oc get catalogsource -n openshift-marketplace`

For more information see [Installing an OpenShit cluster with the Agent-based Installer](https://docs.openshift.com/container-platform/4.18/installing/installing_with_agent_based_installer/installing-with-agent-based-installer.html).

Back to [Hub Cluster Setup](../../README.md).