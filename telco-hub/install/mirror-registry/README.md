# Mirror registry setup

In order to create a mirror registry follow the steps below:

1. Download the mirror registry binary from the [OpenShift console](https://console.redhat.com/openshift/downloads#tool-mirror-registry).
2. [Generate the SSL/TLS certificates](https://docs.redhat.com/en/documentation/red_hat_quay/3/html/proof_of_concept_-_deploying_red_hat_quay/advanced-quay-poc-deployment).
3. Create the mirror registry with the following command:
   `./mirror-registry install --quayHostname <registry.example.com> --sslCert ssl.cert --sslKey ssl.key`.
4. [Install the oc-mirror plugin](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/disconnected_environments/index#installation-oc-mirror-installing-plugin_about-installing-oc-mirror-v2).
5. [Configure the pull-secret to contain the mirror registry credentials](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/disconnected_environments/index#installation-adding-registry-pull-secret_about-installing-oc-mirror-v2).
6. Create the `imageset-config.yaml` file to mirror the OCP release as well as the required operators images.
7. Mirror the images required for a disconnected installation: `oc mirror -c imageset-config.yaml --workspace file://oc-mirror-workspace docker://<registry.example.com:8443> --v2`.
8. Check the mirror registry’s local website (`<registry.example.com:8443>`) to verify that the repositories have been created and that the images have been pushed (see Usage Logs).

For more information see [Disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/disconnected_environments/index).

Back to [Hub Cluster Setup](../../README.md).