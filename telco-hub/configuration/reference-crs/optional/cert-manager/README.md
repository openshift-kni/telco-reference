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

### Certificate Issuers

- `certManagerClusterIssuer.yaml` - **ACME issuer** with DNS-01 challenge (reference recommendation)

### Certificate Resources
- `apiServerCertificate.yaml` - Creates a certificate for the API Server endpoint
- `ingressCertificate.yaml` - Creates a wildcard certificate for the Ingress/Router

### OpenShift Configuration
- `apiServerConfig.yaml` - Configures OpenShift to use the cert-manager generated API Server certificate
- `ingressControllerConfig.yaml` - Configures OpenShift to use the cert-manager generated Ingress certificate

## Customization Required

Before applying these configurations, you must customize the following:

1. **ClusterIssuer** (`certManagerClusterIssuer.yaml`):
   - Update `email` with your contact email
   - Configure the appropriate DNS provider for DNS-01 challenge (example shows Route53)
   - Reference pre-created Secrets for DNS provider credentials via `secretRef` — do not commit credentials in manifests

   > **Note:** Other issuer types (e.g., CA issuer for disconnected environments with existing PKI) are allowable.
   > Users may configure their own ClusterIssuer; currently only ACME issuer is provided in the reference.

2. **Certificates** (`apiServerCertificate.yaml` and `ingressCertificate.yaml`):
   - Update `commonName` and `dnsNames` to match your cluster's domain
   - Example: Replace `api.example.com` with your actual API endpoint
   - Example: Replace `*.apps.example.com` with your actual wildcard domain

3. **APIServer Configuration** (`apiServerConfig.yaml`):
   - Update the `names` field to match your API Server FQDN

## Deployment Order

1. Deploy operator installation files (NS, OperatorGroup, Subscription)
2. Wait for operator to be ready
3. Deploy the ClusterIssuer
4. Deploy the Certificate resources
5. Wait for certificates to be issued and secrets created
6. Apply the APIServer and IngressController configurations

## Certificate Verification

After applying these configurations, verify that:
- Certificates are issued: `oc get certificate -A`
- Secrets are created: `oc get secret api-server-cert -n openshift-config` and `oc get secret ingress-wildcard-cert -n openshift-ingress`
- API Server is using the certificate: Test HTTPS connection to API endpoint
- Ingress is using the certificate: Test HTTPS connection to any route

## Important: Kubeconfig Trust After API Server Cert Replacement

> **Note:** When using a non-publicly-trusted issuer, you must complete this kubeconfig update
> *before* applying the APIServer configuration (step 6 in the deployment order above).
> Applying the APIServer configuration first will lock you out.

> **Warning:** When cert-manager replaces the API server certificate with one signed by a non-publicly-trusted CA,
> existing kubeconfig files become invalid. The embedded `certificate-authority-data` still references
> the original cluster CA and cannot verify the new certificate. All `oc` and API client commands
> will fail with `x509: certificate signed by unknown authority`.

### Updating kubeconfig

1. Extract the new root CA certificate:
   ```bash
   oc get secret root-ca-secret -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/root-ca.crt
   ```

2. Update your kubeconfig to trust the new CA:
   ```bash
   oc config set-cluster $(oc config current-context | cut -d/ -f2) \
     --certificate-authority=/tmp/root-ca.crt --embed-certs
   ```

3. Verify connectivity:
   ```bash
   oc cluster-info
   ```

### Best practice for PKI environments

Generate a root CA once and use it as the root for your PKI (the ACME issuer or CA issuer your clusters will use). Add the root CA PEM to `/etc/pki/ca-trust/source/anchors/` on your workstation and run `update-ca-trust`. All certificates issued from that root CA will then be trusted without per-cluster kubeconfig updates.

## Hub-Spoke Trust with ACM

When cert-manager issues certificates for the hub's API server and ingress, managed spokes must trust the cert-manager root CA to maintain connectivity. The reference configuration includes a `KlusterletConfig` and CA ConfigMap to distribute the root CA to spokes automatically.

### Hub-spoke trust files

- `certManagerHubCAConfigMap.yaml` — ConfigMap in `multicluster-engine` namespace containing the cert-manager root CA, labeled for the import controller
- `certManagerKlusterletConfig.yaml` — KlusterletConfig that switches spoke CA verification from auto-detected leaf cert to the custom root CA bundle

### Why this is needed

By default, ACM embeds the hub's leaf serving cert (`CA:FALSE`) in the klusterlet bootstrap kubeconfig. This means every cert rotation requires a ManifestWork update, and a full CA replacement breaks all spokes immediately. The `KlusterletConfig` with `UseCustomCABundles` replaces the leaf cert with the root CA (`CA:TRUE`), so any certificate signed by that root — current or rotated — is automatically trusted.

### Applying the KlusterletConfig to managed clusters

#### ZTP deployment (recommended)

For fully automated ZTP deployments, configure the ManagedCluster annotation via ClusterInstance `extraAnnotations`:

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

The siteconfig operator automatically applies annotations from `extraAnnotations.ManagedCluster` to the generated ManagedCluster resource, eliminating manual post-deployment steps.

#### Manual deployment

For manual cluster imports or retrofitting existing clusters, annotate the managed cluster after deploying the hub-spoke trust files:

```bash
oc annotate managedcluster <spoke-name> \
  agent.open-cluster-management.io/klusterlet-config=cert-manager-ca-config
```

### Greenfield (cert-manager before spoke deployment)

1. Deploy cert-manager on the hub, create the CA, issue hub API/ingress certs
2. Deploy `certManagerHubCAConfigMap.yaml` and `certManagerKlusterletConfig.yaml`
3. Ensure the KlusterletConfig annotation is configured on managed clusters (see [Applying the KlusterletConfig](#applying-the-klusterletconfig-to-managed-clusters) above)
4. Deploy spokes — they register with the root CA in their trust store
5. Cert rotations are seamless with no intervention required

### Brownfield (cert-manager on existing hub with connected spokes)

The order matters — distribute the CA **before** replacing the hub certs:

1. Install cert-manager on the hub, create the CA — but **do not apply certs to the APIServer/IngressController yet**
2. Deploy `certManagerHubCAConfigMap.yaml` with the root CA PEM
3. Deploy `certManagerKlusterletConfig.yaml`
4. Ensure the KlusterletConfig annotation is configured on all managed clusters (see [Applying the KlusterletConfig](#applying-the-klusterletconfig-to-managed-clusters) above)
5. Wait for the import controller to regenerate bootstrap kubeconfigs (check logs for `create a new bootstrap kubeconfig`)
6. **Now** apply the cert-manager certs to the APIServer and IngressController
7. Spokes stay connected because they already trust the root CA

### Cert rotation

Once the root CA is in the klusterlet's trust store, cert rotations are seamless. The klusterlet trusts any certificate signed by the root CA regardless of serial number, with no ManifestWork timing dependency.

## Root CA Expiration Monitoring

The `certManagerRootCAExpirationPolicy.yaml` creates a PrometheusRule that monitors the root CA certificate expiration using the `certmanager_certificate_expiration_timestamp_seconds` metric:

- **Warning** at 90 days before expiry
- **Critical** at 30 days before expiry

This is distinct from the existing `certManagerCertificatePolicy.yaml` which monitors leaf certificate expiration in `openshift-ingress`, `openshift-config`, and `cert-manager` namespaces via ACM CertificatePolicy. Both should be deployed together for comprehensive certificate monitoring.

## References

- [OpenShift Cert-Manager Operator Documentation](https://docs.openshift.com/container-platform/latest/security/cert_manager_operator/index.html)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [ACME DNS-01 Challenge Configuration](https://cert-manager.io/docs/configuration/acme/dns01/)
- [Hub-Spoke Trust — Complete Solution](https://gist.github.com/sebrandon1/7265d68c5add6adb1313dce5b695e40d)
- [Hub-Spoke Trust Test Results](https://gist.github.com/sebrandon1/483180614951d23174c4e365a9a02a34)
