# GitOps installation instructions

1. Apply the `gitopsNS.yaml` `gitopsOperGroup.yaml` `gitopsSubscription.yaml`.
2. Approve the created InstallPlan on `openshift-gitops`.
3. [Optional] Edit `argocd-ssh-known-hosts-cm.yaml` to add ssh known hosts (public keys) for the git repository you will connect. **Important**: the ConfigMap already exists on the hub cluster, in case you add your own known hosts, apply the yaml instead of creating it.
4. Depending on how you will connect to your git repository (using ssh or https), modify the file `ztp-repo.yaml`. Adapt the file to fill the proper parameters and credentials.
5. Edit the file `ztp-installation/clusters-app.yaml` to set there the connection to the git repository, containing the information about the spoke/managed clusters.
6. Edit the file `ztp-installation/policies-app.yaml` to set there the connection to the git repository, containing the information about the Polices for the spoke/managed clusters.
**Notice**: In both cases, you only need to modify the `path`, `repoURL` and `targetRevision`. For `repoURL`, you have created previously the proper credentials, to access by https or ssl.
7. Apply the patch that will install ZTP inside ArgoCD: `oc patch argocd openshift-gitops -n openshift-gitops --type=merge --patch-file ztp-installation/argocd-openshift-gitops-patch.json`.
8. Apply the different ZTP installation manifests:  `oc apply -k ztp-installation/`.
9. For managing extra-manifest resources (MachineConfigs) on the managedclusters, apply the Extra Manifests Policy (`ztp-policies/extra-manifests-policy.yaml`)
10. Configure Git Repository Webhooks (Optional)

    To eliminate polling delays and receive real-time updates when cluster or policy configurations change:

    1. **Configure webhook in your Git provider** (GitHub, GitLab, etc.):
        - Webhook URL: `https://<argocd-server-url>/api/webhook`
        - Content type: `application/json`
        - Secret: (optional but recommended)

    2. **Set webhook secret in ArgoCD** (if using):
         ```bash
         oc patch secret argocd-secret -n openshift-gitops --patch='{"stringData":{"webhook.<git-provider>.secret":"<your-webhook-secret>"}}'
         ```

    3. **Verify webhook configuration**: Check ArgoCD logs for successful webhook receipts

    See [ArgoCD Webhook Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/) for provider-specific setup details.

Back to [Hub Cluster Setup](../../../../README.md).
