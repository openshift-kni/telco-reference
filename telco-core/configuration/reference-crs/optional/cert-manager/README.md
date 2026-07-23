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

   > **Important:** The reference configuration uses ECDSA P-256 for Certificate resources, which is the recommended algorithm for TLS 1.3.
   > While RSA certificates are still supported for authentication in TLS 1.3, RSA key exchange was removed and RSA does not provide Forward Secrecy.
   > 
   > **Note:** Lifecycle-agent currently has limited support for ECDSA certificates (being addressed in lifecycle-agent PR #7610).
   > For testing purposes, QE may temporarily use RSA certificates, but production deployments should use ECDSA.

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

Generate a root CA once and use it as the root for your PKI (the ACME issuer or CA issuer your clusters will use). Add this root CA to your workstation's system trust store so all certificates issued from it are automatically trusted by workstation tools and browsers. Note that adding the CA to your system trust store does not automatically update existing kubeconfigs with embedded certificate data — see the "Clearing kubeconfig certificate data" section below.

#### Adding CA to system trust store

**Red Hat/Fedora/CentOS:**
```bash
sudo cp /tmp/root-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

**Debian/Ubuntu:**
```bash
sudo cp /tmp/root-ca.crt /usr/local/share/ca-certificates/root-ca.crt
sudo update-ca-certificates
```

**macOS:**
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/root-ca.crt
```

#### Clearing kubeconfig certificate data

**Important:** `oc` and `kubectl` do NOT fall back to the OS trust store if your kubeconfig contains embedded certificate data (`certificate-authority-data` field). You must clear this field to use the system trust store:

```bash
# Remove embedded certificate data from current cluster
CLUSTER_NAME=$(oc config view --minify -o jsonpath='{.clusters[0].name}')
oc config unset "clusters.${CLUSTER_NAME}.certificate-authority-data"

# Verify the OS trust store is now used
oc cluster-info
```

After completing these steps, all future clusters using certificates signed by your root CA will be automatically trusted without per-cluster kubeconfig updates.

## References

- [OpenShift Cert-Manager Operator Documentation](https://docs.openshift.com/container-platform/latest/security/cert_manager_operator/index.html)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [ACME DNS-01 Challenge Configuration](https://cert-manager.io/docs/configuration/acme/dns01/)
