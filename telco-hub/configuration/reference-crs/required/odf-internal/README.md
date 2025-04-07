# ODF installation instructions

1. Create the `odfNS.yaml` `odfOperatorGroup.yaml` `odfSubscription.yaml`.
2. Create the `storageCluster.yaml`.
3. Make the `ocs-storagecluster-cephfs` the default storage class:

   `oc patch storageclass ocs-storagecluster-cephfs --type merge -p '{"metadata": { "annotations": { "storageclass.kubernetes.io/is-default-class": "true" }}}'`

Back to [Hub Cluster Setup](../../../../README.md).