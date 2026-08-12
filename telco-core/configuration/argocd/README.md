# GitOps ZTP for telco-core

The `deployment/` directory contains ArgoCD Applications and RBAC for managing
core spoke clusters via GitOps ZTP:

- `clusters-app.yaml` — syncs `telco-core/install/clusterinstance`
- `policies-app.yaml` — syncs `telco-core/configuration/acmpolicygenerator`

## Prerequisites

Apply the OpenShift GitOps patch before the policies Application can sync
PolicyGenerator CRs:

```bash
oc patch argocd openshift-gitops -n openshift-gitops --type=merge \
  --patch-file argocd/deployment/argocd-openshift-gitops-patch.json
```

Customize the patch for your ACM version (multicluster-operators-subscription
image) following the table in
[telco-ran/configuration/argocd/README.md](../../telco-ran/configuration/argocd/README.md).

Then apply the deployment manifests:

```bash
oc apply -k argocd/deployment/
```

For the full hub preparation and ZTP pipeline overview, see
[telco-ran/configuration/argocd/README.md](../../telco-ran/configuration/argocd/README.md).
