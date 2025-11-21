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
9. For managing MachineConfig extra-manifest resources on the managedclusters, apply the [extra-manifests-policy](ztp-policies/extra-manifests-policy.yaml). More details in [readme](ztp-policies/readme.md).
10. [Optional] Override ArgoCD health check

    ACM has its own [health check](https://github.com/argoproj/argo-cd/tree/master/resource_customizations/policy.open-cluster-management.io/Policy) in Argo CD for Policies.
    This means that the Argo CD Application will be Degraded if any Policy associated to it is NonCompliant.
    This behavior can be changed by overriding the default health check.

    This can be achieved in a couple of ways:

      1. In ACM PolicyGenerator (Preferred):

          Add the following annotation to the PolicyGenerator, under `policyDefaults.policyAnnotations`:

          ```yaml
          apiVersion: policy.open-cluster-management.io/v1
          kind: PolicyGenerator
          metadata:
            name: <policy name>
          policyDefaults:
            namespace: <policy namespace>
            ...
            policyAnnotations:
              argocd.argoproj.io/ignore-healthcheck: "true"
          ```

      2. With the following patch to the `argocd` resource:

          ```bash
          oc patch argocd openshift-gitops \
          -n openshift-gitops \
          --type merge \
          --patch='{"spec":{"resourceHealthChecks":[{"check":"hs = {}\nhs.status = \"Healthy\"\nhs.message = \"Health check overridden\"\nreturn hs\n","group":"policy.open-cluster-management.io","kind":"Policy"}]}}'
          ```
        
      3. Uncomment the `resourceHealthChecks` configuration in the [ztp-argocd-plugins-installer](./addPluginsPolicy.yaml) Policy.

11. [Optional] Configure Git Repository Webhooks

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
