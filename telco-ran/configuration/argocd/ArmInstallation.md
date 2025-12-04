
## Setting up hub cluster

In telco, majority of the cases, the hub cluster will be based on x86 architecture. To deploy a SNO on ARM hardware from x86 hub, will require few additional steps.


### Create clusterImageSet with multiarch image as OCP payload

1. Although multiarch image size is larger than arm specific image, for cross architecture deployment, both x86 and arm64 images are required.

    ```yaml
    apiVersion: hive.openshift.io/v1
    kind: ClusterImageSet
    metadata:
    name: openshift-4.16-multi
    spec:
    releaseImage: quay.io/openshift-release-dev/ocp-release:4.20.1-multi
    ```

2. In the hub, add both x86 and arm64 rootFs and url under `spec.osImages` in the AgentServiceConfig CR.

    ```yaml
    apiVersion: agent-install.openshift.io/v1beta1
    kind: AgentServiceConfig
    metadata:
    annotations:
        unsupported.agent-install.openshift.io/assisted-service-configmap: assisted-service-config
    spec:
    osImages:
    - cpuArchitecture: x86_64
        openshiftVersion: "4.20"
        rootFSUrl: https://rhcos.mirror.openshift.com/art/storage/prod/streams/rhel-9.6/builds/9.6.20250826-1/x86_64/rhcos-9.6.20250826-1-live-rootfs.x86_64.img
        url: https://rhcos.mirror.openshift.com/art/storage/prod/streams/rhel-9.6/builds/9.6.20250826-1/x86_64/rhcos-9.6.20250826-1-live-iso.x86_64.iso
        version: "4.20"
    - cpuArchitecture: arm64
        openshiftVersion: "4.20"
        rootFSUrl: https://mirror.openshift.com/pub/openshift-v4/aarch64/dependencies/rhcos/pre-release/latest-4.20/rhcos-live-rootfs.aarch64.img
        url: https://mirror.openshift.com/pub/openshift-v4/aarch64/dependencies/rhcos/pre-release/latest-4.20/rhcos-live-iso.aarch64.iso
        version: "4.20"
    ```

> Note: The annotation: `unsupported.agent-install.openshift.io/assisted-service-configmap: assisted-service-config` is only needed if unsigned private registry is used. usually for dev purposes and not recommended for production use.

3. When deploying on ARM hardware from x86 HUB, you must specify the correct ironic image within the infraEnv CR to override default ironic image. This image should be based on the OCP release image used in the clusterImageSet. Manually capturing and providing the correct ARM-compatible ironic image is therefore necessary until the [RFE MGMT-19999](https://issues.redhat.com/browse/MGMT-19999) is accepted and relevant PR is merged. If both the Hub and Spoke clusters are based on ARM, the image override is not needed.

    ```shell
        $ oc adm release info --image-for=ironic-agent quay.io/openshift-release-dev/ocp-release:4.20.1-multi

        quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:db36ff22a4b0908c24041336ad7edd72b14e8d78320faa834a67a4970b7a325
    ```


## ClusterInstance

In the ClusterInstance, set the `spec.cpuArchitecture` to aarch64 and add an annotation to override ironic image in the InfraEnv CR. Below is an example:

```yaml
apiVersion: siteconfig.open-cluster-management.io/v1alpha1
kind: ClusterInstance
metadata:
  name: <name>
  namespace: <namespace>
spec:
  clusterName: <clusterName>
  cpuArchitecture: aarch64
  nodes:
    - hostName: "worker-node2.example.com"
        role: "worker"
        extraAnnotations:
          InfraEnv:
            infraenv.agent-install.openshift.io/ironic-agent-image-override: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:82e778fa1d6e378923c0a21c132271ce847983e818c8dafb5762e15a62b9cff6
```

## Additional resources
[Siteconfig Operator - Cpu Architecture section](https://github.com/stolostron/siteconfig/blob/main/docs/cpu_architecture.md?plain=1)