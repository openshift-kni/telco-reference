# Core secret store example

`esoClusterSecretStore.yaml` is provided as an example, and is not part of
te provided `core-baseline.yaml`. The baseline includes ESO, but a Core
secret store is configured separately for the applications and namespaces that
use it.

Before deploying a copy of the example, replace its placeholder name, Vault
endpoint, and the Vault role/mountPath used for Kubernetes authentication,
and set `spec.conditions` with the label
key/value matching the namespaces that should use the store. The example
restricts access to namespaces labeled
`example.com/configure-before-use=required`; label the target namespaces
accordingly (or change the condition to your own selector). **Never set
`conditions: []`: an empty list allows every namespace to use the store.**
Configure Vault's Kubernetes auth method so ESO authenticates with its
`external-secrets` service account; see the Hub ESO README for the full
Vault-side setup, including the token-based alternative when Vault cannot
reach the cluster API server. Add the configured store to a site-specific
policy or apply it by your deployment method. The Core kube-compare reference
allows user-defined non-empty conditions and reports empty or missing ones.
