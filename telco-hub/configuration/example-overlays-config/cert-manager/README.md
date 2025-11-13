# Cert-Manager Overlay Configuration Example

Example overlay for customizing the telco-hub cert-manager configuration with cluster-specific certificate endpoints and ACME settings.

## ClusterIssuer Patch

The `cluster-issuer-patch.yaml` customizes:

1. **ACME server URL**: Production vs staging Let's Encrypt endpoint
2. **Email address**: Contact email for ACME account notifications
3. **DNS provider**: DNS-01 challenge solver configuration (Route53 example)

## Certificate Patches

### Ingress Certificate Patch

The `ingress-certificate-patch.yaml` customizes:

1. **Common Name**: Wildcard certificate for ingress routes (e.g., `*.apps.hub.example.com`)
2. **DNS Names**: Matching DNS SANs for the ingress certificate

### API Server Certificate Patch

The `api-server-certificate-patch.yaml` customizes:

1. **Common Name**: API server FQDN (e.g., `api.hub.example.com`)
2. **DNS Names**: Matching DNS SANs for the API server certificate

## Testing

```bash
# Test the overlay
kubectl kustomize telco-hub/configuration/example-overlays-config/cert-manager/

# Apply the overlay
kubectl apply -k telco-hub/configuration/example-overlays-config/cert-manager/
```

## Key Configuration

- **ACME Server**: Update to production (`https://acme-v02.api.letsencrypt.org/directory`) or staging endpoint
- **Email**: Replace `platform-team@example.com` with your team's email
- **DNS Provider**: Update `dns01` solver for your DNS provider (Route53, CloudFlare, etc.)
  - See: https://cert-manager.io/docs/configuration/acme/dns01/
- **Domain Names**: Update all `*.apps.example.com` and `api.example.com` references to match your cluster's domain

## DNS-01 Challenge

The reference uses DNS-01 challenge for wildcard certificate validation. Ensure your DNS provider credentials are configured as a Secret before deploying. Refer to cert-manager documentation for provider-specific setup.

