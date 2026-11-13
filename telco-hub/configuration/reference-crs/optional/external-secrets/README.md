# External Secrets Operator

ESO is the default reference implementation for secret management in the
telco-hub RDS. Partners may substitute alternative secret management solutions
as long as secrets are not stored in git.

## Installation

1. Create `esoNS.yaml`, `esoOperatorgroup.yaml`, `esoSubscription.yaml`.
2. Wait for the operator to be ready.
3. Create `esoExternalSecretsConfig.yaml` to deploy the operand.
4. Configure Vault authentication for ESO (see below).
5. Create `esoNetworkPolicy.yaml` to allow ESO to reach the secret store.
6. Create `esoClusterSecretStore.yaml`.
7. Create `esoClusterTemplates.yaml` and `esoNodeTemplates.yaml`.

## Optional cert-manager integration

The default `ExternalSecretsConfig` uses `spec: {}`. cert-manager is **not
required** for ESO's webhook certificates: ESO generates them when the
cert-manager certificate provider is not configured. If ESO plugins are used,
their certificates must be configured separately without cert-manager.

To opt in, install and verify the cert-manager Operator and its CA injector
**before** installing ESO. Create an issuer suitable for internal ESO
certificates: an `Issuer` in the `external-secrets` namespace or a
`ClusterIssuer`. The existing optional ACME issuer example is for platform
endpoints; do not assume it can issue ESO's internal webhook certificates.
Then replace `spec: {}` in the Hub or Core `esoExternalSecretsConfig.yaml`
with the commented example in that file, changing the issuer name and kind
to match the issuer you created. For example:

```yaml
spec:
  controllerConfig:
    certProvider:
      certManager:
        injectAnnotations: "true"
        issuerRef:
          name: eso-issuer
          kind: Issuer
          group: cert-manager.io
        mode: Enabled
```

The example requires an `Issuer` named `eso-issuer` in the `external-secrets`
namespace. Use `kind: ClusterIssuer` and the matching name instead if you
have a suitable cluster-scoped issuer. Do not apply the example until the
issuer is ready. `mode` and `injectAnnotations` cannot be changed after they
are configured. For an existing ESO deployment, follow the operator's
migration procedure:
adding cert-manager configuration later requires removing the old
`external-secrets-cert-controller` deployment; installing cert-manager after
ESO also requires restarting the ESO operator pod. These instructions are
based on the [OCP 5.0 ESO documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/external-secrets-operator-for-red-hat-openshift#external-secrets-cert-manager-config_external-secrets-log-levels).
Verify the operator version and API against your 5.0 catalog before deployment.

Hub and Core kube-compare templates accept either the default `spec: {}` or
the cert-manager opt-in. When cert-manager is configured, they check
`injectAnnotations: "true"`, `mode: Enabled`, issuer kind (`Issuer` or
`ClusterIssuer`), and `group: cert-manager.io`, while allowing the issuer name
to vary. The existing `ignore-unspecified-fields` setting permits additional
operator-specific configuration; it does not verify that the referenced issuer
exists or that certificates are issued successfully.

## Vault authentication

The default store uses Vault's **Kubernetes auth method**: ESO authenticates
with the `external-secrets` service account in the `external-secrets`
namespace, so no Vault token is stored in the cluster. Before creating
`esoClusterSecretStore.yaml`, configure Vault:

```bash
# Enable Kubernetes auth (Vault must be able to reach the cluster API server).
vault auth enable -path=kubernetes kubernetes
vault write auth/kubernetes/config \
  kubernetes_host=https://kubernetes.default.svc:443

# Least-privilege policy matching the ZTP template paths.
vault policy write eso-ztp - <<'EOF'
path "secret/data/clusters/*" {
  capabilities = ["read"]
}
EOF

# Bind the role to the ESO controller service account.
vault write auth/kubernetes/role/external-secrets-operator \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=eso-ztp \
  ttl=1h
```

Tokens issued this way are short-lived and renewed automatically by ESO.

If Vault cannot reach the cluster API server (e.g. external Vault without
network access to the hub), Kubernetes auth is not usable. In that case,
substitute the `auth` block with `tokenSecretRef`:

```yaml
auth:
  tokenSecretRef:
    name: vault-token
    key: token
    namespace: external-secrets-operator
```

```bash
oc create secret generic vault-token \
  --from-literal=token='<your-vault-token>' \
  -n external-secrets-operator
```

A static token must never be stored in git. Scope it to a least-privilege
policy and set a TTL; because the templates use `refreshPolicy: OnChange`,
rotating the token in the Vault side requires manually forcing a sync
(`oc annotate externalsecret <name> -n <namespace> force-sync=$(date +%s) --overwrite`).

## ClusterInstance templates

Two template ConfigMaps provide automatic secret provisioning when a
ClusterInstance is created:

- `esoClusterTemplates.yaml` deploys a ConfigMap (`eso-cluster-templates-v1`)
  containing a template for a pull secret ExternalSecret.
- `esoNodeTemplates.yaml` deploys a ConfigMap (`eso-node-templates-v1`)
  containing a template for a BMC credentials ExternalSecret.

When the siteconfig-operator renders a ClusterInstance that references these
templates, it creates ExternalSecret CRs in the cluster namespace. ESO then
fetches the actual secret values from the configured secret store.

### Vault structure contract

**IMPORTANT**: The ExternalSecret templates define a binding contract between the
Hub RDS and your secret store. The paths and property names below MUST be followed
exactly in your Vault (or alternative secret store) deployment.

The templates use the following vault key paths:

- **Pull secret**: `clusters/<cluster-name>/pull-secret`
  - Required property: `.dockerconfigjson` (string containing the full docker config JSON)
  
- **BMC credentials**: `clusters/<cluster-name>/bmc/<hostname>`
  - Required properties:
    - `username` (string)
    - `password` (string)

Where:
- `<cluster-name>` is the value from `ClusterInstance.spec.clusterName`
- `<hostname>` is the value from `ClusterInstance.spec.nodes[].hostName`

**Example Vault structure** for a cluster named "sno-site-1" with one node:

```
secret/data/clusters/sno-site-1/pull-secret
  .dockerconfigjson = '{"auths":{"registry.example.com":{"auth":"..."}}}'

secret/data/clusters/sno-site-1/bmc/node1.sno-site-1.example.com
  username = "admin"
  password = "secretpassword"
```

This contract is documented in the telco-hub RDS. Any deviation from these
paths or property names will cause cluster provisioning to fail.

### Adding templateRefs to a ClusterInstance

Add the ESO template ConfigMaps alongside the existing siteconfig templates
in your ClusterInstance spec:

```yaml
spec:
  templateRefs:
    - name: ai-cluster-templates-v1
      namespace: open-cluster-management
    - name: eso-cluster-templates-v1
      namespace: open-cluster-management
  nodes:
    - hostName: "node1.example.com"
      templateRefs:
        - name: ai-node-templates-v1
          namespace: open-cluster-management
        - name: eso-node-templates-v1
          namespace: open-cluster-management
```

## Security considerations

### Namespace restriction

The ClusterSecretStore includes a `conditions` field with a `namespaceSelector`
that restricts usage to namespaces labeled with
`cluster.open-cluster-management.io/managedCluster` with a non-empty value.
This ensures only RHACM-managed cluster namespaces can create ExternalSecrets
referencing `ztp-secret-provider`. ExternalSecrets in unlabeled namespaces are
rejected.

### Vault access scoping

Whether using Kubernetes auth or a token, the Vault policy should be
least-privilege, limiting access to only the paths required by the ZTP
templates. Example Vault policy:

```hcl
path "secret/data/clusters/*" {
  capabilities = ["read"]
}
```

This restricts access to read-only under `clusters/`, matching the
path convention used by the ClusterInstance templates. Avoid granting broader
access (e.g., `secret/*`) even if convenient during initial setup. With the
Kubernetes auth method, also keep the role binding tight: bind only the ESO
controller service account in the `external-secrets` namespace, and use a
short TTL.

## Network policy

The ESO Operator deploys default NetworkPolicies in the `external-secrets`
operand namespace that deny other traffic but allow access to the OpenShift API
server and DNS. `esoNetworkPolicy.yaml` adds egress to the secret store for the
ESO controller; Kubernetes NetworkPolicy allow rules are additive, so this
policy does not need to repeat the API-server or DNS rules. Check that the
Operator's default policies are present and allow the required traffic on the
target cluster. Other workloads' policies must be evaluated separately. Update
the target namespace label and port in the overlay patch to match your environment.

## Customization required

- `ztp-secret-provider` is an example `ClusterSecretStore` name, not a required
  name. If you rename the store, update `secretStoreRef.name` in both
  `esoClusterTemplates.yaml` and `esoNodeTemplates.yaml` to match. The Hub and
  Core kube-compare store templates accept any `metadata.name`.
- Update `esoClusterSecretStore.yaml` with your secret store address, path,
  and authentication method. The Vault example is illustrative; any provider
  supported by ESO may be used.
- Update `esoNetworkPolicy.yaml` target namespace and port to match your
  secret store deployment (defaults to namespace `vault`, port 8200).
- Adjust the vault key paths in `esoClusterTemplates.yaml` and
  `esoNodeTemplates.yaml` if your secret store uses a different path layout.

Back to [Hub Cluster Setup](../../../../README.md).
