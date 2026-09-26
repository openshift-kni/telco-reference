# External Secrets Operator

ESO is the default reference implementation for secret management in the
telco-hub RDS. Partners may substitute alternative secret management solutions
as long as secrets are not stored in git.

## Installation

1. Create `esoNS.yaml`, `esoOperatorgroup.yaml`, `esoSubscription.yaml`.
2. Wait for the operator to be ready.
3. Create `esoExternalSecretsConfig.yaml` to deploy the operand.
4. Inject the vault access secret into the cluster (see below).
5. Create `esoNetworkPolicy.yaml` to allow ESO to reach the secret store.
6. Create `esoClusterSecretStore.yaml`.
7. Create `esoClusterTemplates.yaml` and `esoNodeTemplates.yaml`.

## Vault access secret

The `vault-token` secret referenced by `esoClusterSecretStore.yaml` must be
created by the user after the Hub is configured. It must never be stored in
git.

```bash
oc create secret generic vault-token \
  --from-literal=token='<your-vault-token>' \
  -n external-secrets-operator
```

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
`cluster.open-cluster-management.io/managedCluster`. This ensures only
RHACM-managed cluster namespaces can create ExternalSecrets referencing
`ztp-secret-provider`. ExternalSecrets in unlabeled namespaces are rejected.

### Vault token scoping

The `vault-token` secret should use a least-privilege Vault policy that limits
access to only the paths required by the ZTP templates. Example Vault policy:

```hcl
path "secret/data/clusters/*" {
  capabilities = ["read"]
}
```

This restricts the token to read-only access under `clusters/`, matching the
path convention used by the ClusterInstance templates. Avoid granting broader
access (e.g., `secret/*`) even if convenient during initial setup.

## Network policy

The ESO operator deploys a `deny-all-traffic` NetworkPolicy in the `external-secrets`
operand namespace. `esoNetworkPolicy.yaml` adds an egress rule allowing the ESO
controller to reach the secret store. Update the target namespace label and port
in the overlay patch to match your environment.

## Customization required

- Update `esoClusterSecretStore.yaml` with your secret store address, path,
  and authentication method. The Vault example is illustrative; any provider
  supported by ESO may be used.
- Update `esoNetworkPolicy.yaml` target namespace and port to match your
  secret store deployment (defaults to namespace `vault`, port 8200).
- Adjust the vault key paths in `esoClusterTemplates.yaml` and
  `esoNodeTemplates.yaml` if your secret store uses a different path layout.

Back to [Hub Cluster Setup](../../../../README.md).
