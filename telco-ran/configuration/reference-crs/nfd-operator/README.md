# Node Feature Discovery Operator

The optional Red Hat Node Feature Discovery (NFD) Operator labels nodes with
detected hardware features.

Enable the NFD installation entries in `ran-common.yaml` and the instance entry in the SNO, three-node, or standard group policy for your cluster.

The Subscription installs NFD from the shared `redhat-operators-disconnected`
catalog on the `stable` channel. For disconnected deployments, include NFD and
its related images in your mirror. The installed operator selects the operand
image.

See the [Red Hat OpenShift 5.1 NFD documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/5.1/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator).
