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

Set `ca-bundle.crt` in `certManagerHubCAConfigMap.yaml` to the PEM of the root CA that issued the hub API server certificate. For a CA issuer this is the CA certificate in the secret referenced by the issuer. For an ACME issuer it is the root of the ACME server's chain.

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

### Greenfield (cert-manager before spoke deployment)

1. Deploy cert-manager on the hub, configure the issuer and issue the hub API and ingress certificates
2. Deploy `certManagerHubCAConfigMap.yaml` and `certManagerKlusterletConfig.yaml`
3. Configure the KlusterletConfig annotation on managed clusters (see [Applying the KlusterletConfig](#applying-the-klusterletconfig-to-managed-clusters))
4. Deploy spokes. They register with the root CA in their trust bundle.

### Brownfield (cert-manager on an existing hub with connected spokes)

Distribute the root CA **before** replacing the hub certificates:

1. Install cert-manager on the hub and configure the issuer, but **do not apply the certificates to the APIServer or IngressController yet**
2. Deploy `certManagerHubCAConfigMap.yaml` with the root CA PEM
3. Deploy `certManagerKlusterletConfig.yaml`
4. Configure the KlusterletConfig annotation on all managed clusters
5. Wait for the import controller to regenerate the bootstrap kubeconfigs (its logs show `create a new bootstrap kubeconfig`)
6. Apply the cert-manager certificates to the APIServer and IngressController
7. Spokes stay connected because they already trust the root CA

### Certificate renewal

Once the root CA is in the klusterlet trust bundle, renewals need no intervention. The klusterlet trusts any certificate signed by the root CA, with no ManifestWork timing dependency. Replacing the root CA itself requires adding the new root to the ConfigMap before switching the hub certificate.

## References

- [OpenShift Cert-Manager Operator Documentation](https://docs.openshift.com/container-platform/latest/security/cert_manager_operator/index.html)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [ACME DNS-01 Challenge Configuration](https://cert-manager.io/docs/configuration/acme/dns01/)
- [ACM: Setting the hub cluster KubeAPIServer verification strategy](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html-single/clusters/index#set-hub-kube-api-server)
