# Delete and re-provision a worker node using ZTP

Starting from ACM 2.8, it supports GitOps workflow to cleanly delete a node from an existing cluster by deleting the BMH CR on the hub cluster that is annotated for cleanup. This document provides guidance on how to delete and re-provision a worker node using ZTP workflow.

## Prerequisites

1. A spoke cluster (ie. Standard, Compact+workers, sno+workers) installed and configured using the GitOps ZTP flow, as described in [GitOps ZTP flow](README.md)
1. ACM 2.8+ with MultiClusterHub created and configured, running on OCP 4.13+ bare metal cluster

## Delete a worker node from spoke cluster

1. Annotate the BMH CR of the worker node with the "bmac.agent-install.openshift.io/remove-agent-and-node-on-delete=true" annotation. Add the annotation using `extraAnnotations` via ClusterInstance as the following, then push the changes to git repo and wait for the BMH CR on the hub cluster has the annotation applied.

    ```yaml
    nodes:
    - hostName: "worker-node2.example.com"
        role: "worker"
        extraAnnotations:
          BareMetalHost:
            bmac.agent-install.openshift.io/remove-agent-and-node-on-delete: "true"
    ```

2. Delete the BMH CR of the worker node that has been annotated. Suppress the generation of the BMH CR using via ClusterInstance as the following, then push the changes to git repo and wait for deprovision to start.

   ```yaml
    nodes:
      - hostName: "worker-node2.example.com"
        role: "worker"
        pruneManifests:
          - apiVersion: metal3.io/v1alpha1
            kind: BareMetalHost
   ```

3. The status of the BMH CR should be changed to "deprovisioning". Wait for the BMH to finish deprovisioning, and to be fully deleted.


## Verify the node is deleted

1. Verify the BMH and Agent CRs for the worker node have been deleted from the hub cluster.

```shell
oc get bmh -n <cluster-ns>
oc get agent -n <cluster-ns>
```

2. Verify the node record has been deleted from the spoke cluster.

```shell
oc get nodes
```

## Update ClusterInstance

After the `BareMetalHost` object of the worker node is successfully deleted, remove the associated worker node definition from the `spec.nodes` section in the `ClusterInstance` resource.

## Official documentation

- [Adding annotations to any Underlying CR or any worker node](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/multicluster_engine_operator_with_red_hat_advanced_cluster_management/index#scale-add-annotation)  


- [Delete BMH of worker nodes](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/multicluster_engine_operator_with_red_hat_advanced_cluster_management/index#scale-in-delete-baremetal-host)
