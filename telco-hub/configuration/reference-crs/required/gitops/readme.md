# Installation instructions

1 - Apply the `gitopsNS.yaml` `gitopsOperGroup.yaml` `gitopsSubscription.yaml`.  

 2 - Approve the created InstallPlan on `openshift-gitops`.  

 3 - [Optional] Edit `argocd-ssh-known-hosts-cm.yaml` to add ssh known hosts (public keys) for the git repository you will connect. **Important**: the ConfigMap already exists on the hub cluster, in case you add your own known hosts, apply the yaml instead of creating it.  

 4 - Depending on how you will connect to your git repository (using ssh or https), modify the file `ztp-repo.yaml`. Adapt the file to fill the proper parameters and credentials. 

 5 -  Edit the file `ztp-installation/clusters-app.yaml` to set there the connection to the git repository, containing the information about the spoke/managed clusters.  

 6 -  Edit the file `ztp-installation/policies-app.yaml` to set there the connection to the git repository, containing the information about the Polices for the spoke/managed clusters. 

 **Notice**: In both cases, you only need to modify the `path`, `repoURL` and `targetRevision`. For `repoURL`, you have created previously the proper credentials, to access by https or ssl. 

  7 - Apply the patch that will install ZTP inside ArgoCD: `oc patch argocd openshift-gitops -n openshift-gitops --type=merge --patch-file ztp-installation/argocd-openshift-gitops-patch.json` 

  8 - Finally apply the different ZTP installation manifests:  `oc apply -k ztp-installation/`
