# Installation instructions

  1 - Create the `acmNS.yaml` `acmOperGroup.yaml` `acmSubscription.yaml`
  2 - Approve the created InstallPlan on `open-cluster-management`
  3 - Create the `acmMCH.yaml`
  4 - Approve the created InstallPlan on `multicluster-engine`
  5 - Apply the `acmProvisioning.yaml` ?
  6 - Create the  `acmAgentServiceConfig.yaml`
  7 - The `multicluster-engine` enables the `cluster-proxy-addon` feature by default. Apply the following patch to disable it: `oc patch multiclusterengines.multicluster.openshift.io multiclusterengine --type=merge --patch-file ./disable-cluster-proxy-addon.json`
  8 - Create the `observabilityNS.yaml`  
  9 - Enabling MultiClusterHub Observability. Check first [pre-requirements](./pre-requeriments.md)
  10 - Create the `observabilityMCO.yaml`
