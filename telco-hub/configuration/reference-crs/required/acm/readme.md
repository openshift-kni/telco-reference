# Installation instructions

1. Create the `acmNS.yaml` `acmOperGroup.yaml` `acmSubscription.yaml`.
2. If Subscription was set to Manual installPlanApproval, approve the created InstallPlan on `open-cluster-management`
3. Create the `acmMCH.yaml`.
4. If Subscription was set to Manual installPlanApproval, approve the created InstallPlan on `multicluster-engine`
5. Apply the `acmProvisioning.yaml`.
6. Create the `acmAgentServiceConfig.yaml` (Two PVs are required, so ODF must be configured prior to this step).
7. The `multicluster-engine` enables the `cluster-proxy-addon` feature by default. Apply the following patch to disable it: `oc patch multiclusterengines.multicluster.openshift.io multiclusterengine --type=merge --patch-file ./disable-cluster-proxy-addon.json`.
8. Create the `observabilityNS.yaml`.
9. Generate the pull-secret `observabilitySecret.yaml`. The value for the `.dockerconfigjson` field can be found as follows:
    - Try `oc extract secret/multiclusterhub-operator-pull-secret -n open-cluster-management --to=-`.
    - If the previous command returns an empty value use: `oc extract secret/pull-secret -n openshift-config --to=-`.
10. Create the `observabilityOBC.yaml`.
11. Create the Thanos secret `thanosSecret.yaml`.
    - The `bucket` and the `endpoint` can be obtained from the ConfigMap that the OBC automatically creates in its namespace. Use the fields `BUCKET_NAME` (without any protocol or port specification) and `BUCKET_HOST` respectively.
    - The `access_key` and the `secret_key` can be obtained from the Secret that the OBC creates automatically in its namespace. Use the fields `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` respectively. This two fields are encoded in base64 in the OBC Secret but must be decoded in the Thanos Secret (use `echo -n "<string>" | base64 -d` to decode it).
12. Create the `observabilityMCO.yaml`.
13. When all the installation is done. Apply the `acmPerfSearch.yaml` .This will configure Search CR called `search-v2-operator` considering different performance and scale optimizations.
