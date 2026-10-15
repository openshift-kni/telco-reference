# Cert-Manager Configuration

This directory contains optional configurations for using cert-manager to manage TLS certificates in OpenShift.

## Overview

Cert-manager automates the management and issuance of TLS certificates from various issuing sources. This configuration demonstrates how to:
- Install the cert-manager operator
- Configure an ACME issuer using DNS-01 challenge
- Generate and use custom certificates for API Server and Ingress endpoints

## Files

### Operator Installation
- `certManagerNS.yaml` - Creates the cert-manager-operator namespace
- `certManagerOperatorgroup.yaml` - Creates the OperatorGroup for cert-manager
- `certManagerSubscription.yaml` - Installs the OpenShift cert-manager operator

### Certificate Issuer
- `certManagerClusterIssuer.yaml` - Configures an ACME ClusterIssuer using Let's Encrypt with DNS-01 challenge

### Certificate Resources
- `apiServerCertificate.yaml` - Creates a certificate for the API Server endpoint
- `ingressCertificate.yaml` - Creates a wildcard certificate for the Ingress/Router

### OpenShift Configuration
- `apiServerConfig.yaml` - Configures OpenShift to use the cert-manager generated API Server certificate
- `ingressControllerConfig.yaml` - Configures OpenShift to use the cert-manager generated Ingress certificate

### Hub-Spoke Trust
- `certManagerHubCAConfigMap.yaml` - ConfigMap in the `multicluster-engine` namespace containing the root CA that issued the hub API server certificate, labeled for the import controller
- `certManagerKlusterletConfig.yaml` - KlusterletConfig that switches spoke verification of the hub API server from the auto-detected CA bundle to the custom root CA bundle

## Customization Required

Before applying these configurations, you must customize the following:

1. **ClusterIssuer** (`certManagerClusterIssuer.yaml`):
   - Update `email` with your contact email
   - Configure the appropriate DNS provider for DNS-01 challenge (example shows Route53)
   - Add necessary credentials for your DNS provider

2. **Certificates** (`apiServerCertificate.yaml` and `ingressCertificate.yaml`):
   - Update `commonName` and `dnsNames` to match your cluster's domain
   - Example: Replace `api.example.com` with your actual API endpoint
   - Example: Replace `*.apps.example.com` with your actual wildcard domain

3. **APIServer Configuration** (`apiServerConfig.yaml`):
   - Update the `names` field to match your API Server FQDN

4. **Hub CA ConfigMap** (`certManagerHubCAConfigMap.yaml`):
   - Replace `<replace with root CA PEM>` with the CA bundle (see [Populating the CA ConfigMap](#populating-the-ca-configmap))
   - Do not annotate any managed cluster with `cert-manager-ca-config` while the placeholder is in place. Spokes that select the KlusterletConfig trust only this bundle.

## Deployment Order

1. Deploy operator installation files (NS, OperatorGroup, Subscription)
2. Wait for operator to be ready
3. Deploy the ClusterIssuer
4. Wait for certificates to be issued and secrets created
5. Apply the APIServer and IngressController configurations

## Certificate Verification

After applying these configurations, verify that:
- Certificates are issued: `oc get certificate -A`
- Secrets are created: `oc get secret api-server-cert -n openshift-config` and `oc get secret ingress-wildcard-cert -n openshift-ingress`
- API Server is using the certificate: Test HTTPS connection to API endpoint
- Ingress is using the certificate: Test HTTPS connection to any route

## Hub-Spoke Trust with ACM

When cert-manager issues the hub API server certificate, managed spokes must trust the root CA of the issuer to stay connected to the hub. The `KlusterletConfig` and CA ConfigMap distribute that root CA to spokes through the klusterlet bootstrap kubeconfig.

> **Requirements:** ACM 2.11 or later. The `serverVerificationStrategy` field used by the KlusterletConfig was introduced in ACM 2.11.

### Why this is needed

By default (`UseAutoDetectedCABundle`), ACM embeds the CA bundle it detects from the hub API server certificate secret in the klusterlet bootstrap kubeconfig. When cert-manager stores only the leaf and intermediate certificates in that secret, spokes end up trusting the intermediate or leaf instead of the root. A renewal that changes the intermediate, or a CA replacement, then disconnects every spoke. The `KlusterletConfig` with `UseCustomCABundles` gives spokes the root CA (`CA:TRUE`), so any certificate signed by that root, current or renewed, is trusted.

### Populating the CA ConfigMap

Set `ca-bundle.crt` in `certManagerHubCAConfigMap.yaml` to the PEM of the root CA at the top of the chain that issued the hub API server certificate. Do not use an intermediate: spokes would trust only that intermediate, and a change to it would disconnect them.

- **CA issuer:** start from the CA certificate in the secret the issuer references. If that CA is itself an intermediate, follow its chain up to the root.
- **ACME issuer:** use the root certificate published by the ACME CA. ACME servers usually send only the leaf and intermediates, not the root.

A root CA is self-signed, so its subject and issuer match, and it has `CA:TRUE`:

```bash
openssl x509 -in root-ca.pem -noout -subject -issuer -ext basicConstraints
```

With `UseCustomCABundles`, this bundle **replaces** the auto-detected CA in the spoke's bootstrap kubeconfig instead of adding to it. When the klusterlet agent picks up the new bootstrap kubeconfig, it trusts only the certificates in this ConfigMap. If the hub still serves a certificate from another CA, include that CA in the bundle too. On a hub that still serves the default OpenShift API certificate (brownfield), that means appending the OpenShift API serving CAs:

```bash
oc -n openshift-kube-apiserver get configmap kube-apiserver-server-ca \
  -o jsonpath='{.data.ca-bundle\.crt}' > ocp-api-server-ca.pem
cat root-ca.pem ocp-api-server-ca.pem > ca-bundle.crt
```

`ca-bundle.crt` can hold several PEM certificates.

### Applying the KlusterletConfig to managed clusters

#### ZTP deployment (recommended)

Set the ManagedCluster annotation through ClusterInstance `extraAnnotations`. The siteconfig operator applies it to the generated ManagedCluster:

```yaml
apiVersion: siteconfig.open-cluster-management.io/v1alpha1
kind: ClusterInstance
metadata:
  name: spoke-cluster-name
  namespace: spoke-cluster-namespace
spec:
  clusterName: spoke-cluster-name
  extraAnnotations:
    ManagedCluster:
      agent.open-cluster-management.io/klusterlet-config: "cert-manager-ca-config"
  # ... rest of ClusterInstance spec
```

The example ClusterInstance CRs in `telco-ran/install/clusterinstance/` and `telco-core/install/` include this annotation commented out.

#### Manual deployment

For manually imported clusters, or to retrofit existing clusters, annotate each managed cluster after deploying the hub-spoke trust files:

```bash
oc annotate managedcluster <spoke-name> \
  agent.open-cluster-management.io/klusterlet-config=cert-manager-ca-config
```

The annotation names a single KlusterletConfig. If a cluster already has a `agent.open-cluster-management.io/klusterlet-config` annotation, `oc annotate` refuses to change it. Do not force it with `--overwrite`: that drops the settings in the existing KlusterletConfig, such as proxy or node placement. Instead, add the `hubKubeAPIServerConfig` section from `certManagerKlusterletConfig.yaml` to the KlusterletConfig the cluster already uses.

### Greenfield (cert-manager before spoke deployment)

1. Deploy cert-manager on the hub, configure the issuer and issue the hub API and ingress certificates
2. Deploy `certManagerHubCAConfigMap.yaml` and `certManagerKlusterletConfig.yaml`
3. Configure the KlusterletConfig annotation on managed clusters (see [Applying the KlusterletConfig](#applying-the-klusterletconfig-to-managed-clusters))
4. Deploy spokes. They register with the root CA in their trust bundle.

### Brownfield (cert-manager on an existing hub with connected spokes)

Distribute the root CA **before** replacing the hub certificates, and keep the hub's current CA in the bundle until the switch is done:

1. Install cert-manager on the hub and configure the issuer, but **do not apply the certificates to the APIServer or IngressController yet**
2. Deploy `certManagerHubCAConfigMap.yaml` with the root CA PEM **and** the OpenShift API serving CAs the hub uses today (see [Populating the CA ConfigMap](#populating-the-ca-configmap)). A bundle with only the root CA disconnects every annotated spoke within minutes, because the hub still serves a certificate the spokes no longer trust.
3. Deploy `certManagerKlusterletConfig.yaml`
4. Configure the KlusterletConfig annotation on all managed clusters
5. Wait for the import controller to regenerate the bootstrap kubeconfigs. Its log shows `create a new bootstrap kubeconfig for the managed cluster <name>`. The import controller runs two replicas, so check both pods' logs. To see the CAs a spoke will receive, list the bundle in its klusterlet ManifestWork; it must include both the root CA and the OpenShift API serving CAs:

   ```bash
   oc -n <spoke-name> get manifestwork <spoke-name>-klusterlet \
     -o jsonpath='{.spec.workload.manifests[?(@.metadata.name=="bootstrap-hub-kubeconfig")].data.kubeconfig}' \
     | base64 -d | awk '/certificate-authority-data/ {print $2}' | base64 -d \
     | openssl crl2pkcs7 -nocrl -certfile /dev/stdin | openssl pkcs7 -print_certs -noout | grep subject
   ```

6. Confirm each spoke reconnected after its klusterlet agent restarted: `ManagedClusterConditionAvailable=True`, and `managed-cluster-lease` in the cluster namespace still renewing
7. Apply the cert-manager certificates to the APIServer and IngressController
8. Spokes stay connected because they already trust the root CA
9. Optional: remove the OpenShift API serving CAs from the ConfigMap so the spokes trust only the root CA. Do this only after the hub serves the cert-manager certificate. Before reverting the hub to the OpenShift-managed certificate later, add them back and wait for the spokes to pick them up.

### Certificate renewal

Once the root CA is in the klusterlet trust bundle, renewals need no intervention. The klusterlet trusts any certificate signed by the root CA, with no ManifestWork timing dependency. Replacing the root CA itself requires adding the new root to the ConfigMap, alongside the old one, before switching the hub certificate.

### Recovering a disconnected spoke

If a spoke shows `AVAILABLE=Unknown` and its klusterlet agent logs `x509: certificate signed by unknown authority`, its bootstrap kubeconfig does not trust the certificate the hub serves. The spoke cannot recover on its own: the hub delivers the corrected bootstrap kubeconfig through the klusterlet ManifestWork, and the spoke cannot fetch it while the TLS check fails.

1. Fix the ConfigMap so it includes the CA of the certificate the hub serves.
2. Wait until the `<cluster>-klusterlet` ManifestWork in the cluster namespace contains the fixed bundle in its `bootstrap-hub-kubeconfig` secret. Do not skip this wait. When the spoke reconnects, its work agent applies the ManifestWork contents, and a stale bundle overwrites the repair.
3. On the spoke, write the same bundle into the kubeconfig stored under the `kubeconfig` key of secret `open-cluster-management-agent/bootstrap-hub-kubeconfig`. `certificate-authority-data` is a field inside that kubeconfig, not a key of the secret:

   ```bash
   # On the hub: the fixed bundle from the ManifestWork
   oc -n <spoke-name> get manifestwork <spoke-name>-klusterlet \
     -o jsonpath='{.spec.workload.manifests[?(@.metadata.name=="bootstrap-hub-kubeconfig")].data.kubeconfig}' \
     | base64 -d | awk '/certificate-authority-data/ {print $2}' > ca-bundle.b64

   # On the spoke: replace certificate-authority-data in the stored kubeconfig
   oc -n open-cluster-management-agent get secret bootstrap-hub-kubeconfig \
     -o jsonpath='{.data.kubeconfig}' | base64 -d > bootstrap.kubeconfig
   cluster="$(oc --kubeconfig bootstrap.kubeconfig config view -o jsonpath='{.clusters[0].name}')"
   oc --kubeconfig bootstrap.kubeconfig config set \
     "clusters.$cluster.certificate-authority-data" "$(cat ca-bundle.b64)"
   oc -n open-cluster-management-agent set data secret/bootstrap-hub-kubeconfig \
     --from-file=kubeconfig=bootstrap.kubeconfig
   ```

4. Delete the klusterlet agent pods (`oc -n open-cluster-management-agent delete pod -l app=klusterlet-agent`). `oc rollout restart` does not work, because the klusterlet operator reverts the deployment change.

Re-importing the spoke also works.

## References

- [OpenShift Cert-Manager Operator Documentation](https://docs.openshift.com/container-platform/latest/security/cert_manager_operator/index.html)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [ACME DNS-01 Challenge Configuration](https://cert-manager.io/docs/configuration/acme/dns01/)
- [ACM: Setting the hub cluster KubeAPIServer verification strategy](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html-single/clusters/index#set-hub-kube-api-server)
