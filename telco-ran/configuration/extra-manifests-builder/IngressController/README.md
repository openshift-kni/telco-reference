# Manifests in `extra-manifests-builder/IngressController`

This directory contains manifests for configuring the OpenShift IngressController. Each file is listed below with a summary, a link, and performance notes.

---

## [75-ocp4-cis-kubelet-configure-tls-cipher-suites-ingresscontroller.yaml](./75-ocp4-cis-kubelet-configure-tls-cipher-suites-ingresscontroller.yaml)
**Purpose:** Configures the IngressController to use a custom set of strong TLS cipher suites and sets the minimum TLS version to 1.2 for ingress traffic.
**Potential Performance Impact:**
- Enforcing strong ciphers and TLS 1.2+ improves security and compliance.
- May prevent connections from legacy clients that do not support these ciphers or TLS versions.
- Modern ciphers (e.g., AES-GCM, CHACHA20) are efficient on most hardware, but there may be a slight increase in CPU usage for cryptographic operations compared to weaker/legacy ciphers.
- No impact for modern clients and hardware; possible handshake failures for outdated clients.

---

## General Notes
- **Testing:** Always test TLS/cipher changes in a non-production environment first, as some clients or integrations may not support the new settings.
- **Monitoring:** After applying, monitor ingress logs and client connection errors for any issues.

*Last updated: June 2, 2025*
