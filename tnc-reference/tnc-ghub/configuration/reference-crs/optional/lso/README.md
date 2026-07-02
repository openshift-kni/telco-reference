# LSO installation instructions

1. Create the `lsoNS.yaml` `lsoOperatorGroup.yaml` `lsoSubscription.yaml`.
2. Label all nodes with storage volumes with:

   `oc label node <node-name> cluster.ocs.openshift.io/openshift-storage=`
3. Create the `lsoLocalVolume.yaml`.
4. Check that the PVs have been created:

   `oc get pv`

Back to [Hub Cluster Setup](../../../../README.md).