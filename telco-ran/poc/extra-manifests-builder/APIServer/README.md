# Manifests in `extra-manifests-builder/APIServer`

This directory contains manifests for configuring the OpenShift API Server. Each file is listed below with a summary, a link, and performance notes.

---

## [75-ocp4-cis-api-server-encryption-provider-cipher.yaml](./75-ocp4-cis-api-server-encryption-provider-cipher.yaml)
**Purpose:** Sets the encryption provider cipher for the OpenShift API Server to `aescbc`.
**Potential Performance Impact:**
- Using `aescbc` (AES CBC mode) provides strong encryption for etcd-stored secrets and resources.
- There is a small CPU overhead for encrypting/decrypting resources at rest, but this is generally negligible for most clusters.
- May slightly increase API server latency for large or frequent secret/configmap operations, but is recommended for compliance and security.

---

## [75-ocp4-e8-api-server-encryption-provider-cipher.yaml](./75-ocp4-e8-api-server-encryption-provider-cipher.yaml)
**Purpose:** Also sets the encryption provider cipher for the OpenShift API Server to `aescbc` (E8 profile variant).
**Potential Performance Impact:**
- Same as above: negligible CPU overhead, strong security, and minor impact on API server latency for encrypted resources.

---

## [75-ocp4-cis-audit-profile-set.yaml](./75-ocp4-cis-audit-profile-set.yaml)
**Purpose:** Sets the audit profile for the OpenShift API Server to `WriteRequestBodies`, which increases the level of audit logging to include request bodies for write operations.
**Potential Performance Impact:**
- Increased audit logging can result in higher disk usage and more detailed logs.
- May slightly increase API server CPU and I/O usage, especially in clusters with high write activity.
- Useful for compliance and troubleshooting, but monitor log volume and storage.

---

## General Notes
- **Testing:** Always test encryption and audit changes in a non-production environment first, as changing encryption providers can trigger a re-encryption of all resources and audit settings can increase log volume.
- **Monitoring:** After applying, monitor API server logs, etcd health, and disk usage for any issues.

*Last updated: June 2, 2025*
