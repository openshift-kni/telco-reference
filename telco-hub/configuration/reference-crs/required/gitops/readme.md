# Installation instructions

 1 - Create the `gitopsNS.yaml` `gitopsOperGroup.yaml` `gitopsSubscription.yaml`
 2 - Approve the created InstallPlan on `openshift-gitops`
 3 - [Optional] Edit `ex-argocd-ssh-known-hosts-cm.yaml` to add ssh known hosts (public keys) for the git repository you will connect. **Important**: the ConfigMap already exists on the hub cluster, in case you add your own known hosts, apply the yaml instead of creating it.
 4 - Depending on how you will connect to your git repository (using ssh or https), modify the example files `ex-ztp-repo-https.yaml` or `ex-ztp-repo-ssh.yaml`. Adapt the file to fill the proper parameters and credentials.
 5 -  
