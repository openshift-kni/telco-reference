# Telco-Hub Reference-CRs Sync-Wave Documentation

## Overview

This document defines the deterministic ArgoCD sync-wave ordering for telco-hub reference custom resources (CRs). The structure ensures reliable, predictable deployments by following Kubernetes native resource ordering principles and dependency management.

## Sync-Wave Structure

### **Sync-Wave -50: Registry Foundation**

Cluster-wide registry configuration that affects image pulling across the platform.

**Resources:**

- `required/registry/operator-hub.yaml` - OperatorHub
- `required/registry/catalog-source.yaml` - CatalogSource  
- `required/registry/idms-operator.yaml` - ImageDigestMirrorSet
- `required/registry/idms-release.yaml` - ImageDigestMirrorSet
- `required/registry/itms-generic.yaml` - ImageTagMirrorSet
- `required/registry/itms-release.yaml` - ImageTagMirrorSet

**Rationale:** Registry settings must be configured before any operators or workloads attempt to pull images.

### **Sync-Wave -45: Namespaces**

All namespaces required by subsequent resources, following kubectl native resource order.

**Resources:**

- `required/acm/acmNS.yaml` - Namespace (open-cluster-management)
- `required/acm/observabilityNS.yaml` - Namespace (open-cluster-management-observability)
- `required/gitops/gitopsNS.yaml` - Namespace (openshift-gitops-operator)
- `optional/lso/lsoNS.yaml` - Namespace (openshift-local-storage)
- `optional/odf-internal/odfNS.yaml` - Namespace (openshift-storage)
- `optional/logging/clusterLogNS.yaml` - Namespace (openshift-logging)
- `optional/cert-manager/certManagerNS.yaml` - Namespace (cert-manager)
- `required/gitops/addPluginsPolicy.yaml` - Namespace (hub-policies namespace extracted from this file)

**Rationale:** Namespaces must exist before any namespaced resources can be created.

### **Sync-Wave -40: Namespaced Resources**

All resources that must be created within namespaces, including RBAC, ConfigMaps, Secrets, and operator installation components.

**Resource Categories:**

**RBAC:**

- `required/gitops/clusterrole.yaml` - ClusterRole
- `required/gitops/clusterrolebinding.yaml` - ClusterRoleBinding
- `optional/logging/clusterLogServiceAccount.yaml` - ServiceAccount
- `optional/logging/clusterLogServiceAccountAuditBinding.yaml` - ClusterRoleBinding
- `optional/logging/clusterLogServiceAccountInfrastructureBinding.yaml` - ClusterRoleBinding

**ConfigMaps & Secrets:**

- `required/gitops/argocd-ssh-known-hosts-cm.yaml` - ConfigMap
- `required/gitops/argocd-tls-certs-cm.yaml` - ConfigMap
- `required/gitops/ztp-repo.yaml` - Secret
- `required/acm/observabilitySecret.yaml` - Secret

**OperatorGroups:**

- `required/acm/acmOperGroup.yaml` - OperatorGroup
- `required/gitops/gitopsOperatorGroup.yaml` - OperatorGroup
- `optional/lso/lsoOperatorGroup.yaml` - OperatorGroup
- `optional/odf-internal/odfOperatorGroup.yaml` - OperatorGroup
- `optional/logging/clusterLogOperGroup.yaml` - OperatorGroup
- `optional/cert-manager/certManagerOperatorgroup.yaml` - OperatorGroup

**Subscriptions:**

- `required/acm/acmSubscription.yaml` - Subscription
- `required/gitops/gitopsSubscription.yaml` - Subscription
- `required/talm/talmSubscription.yaml` - Subscription
- `optional/lso/lsoSubscription.yaml` - Subscription
- `optional/odf-internal/odfSubscription.yaml` - Subscription
- `optional/logging/clusterLogSubscription.yaml` - Subscription
- `optional/cert-manager/certManagerSubscription.yaml` - Subscription

**Rationale:** Operator installation and basic platform configuration must complete before custom resources can be deployed.

### **Sync-Wave -35: ArgoCD Resources**

ArgoCD applications and projects, deployed when ArgoCD is guaranteed to be running.

**Resources:**

- `required/gitops/app-project.yaml` - AppProject
- `required/gitops/argocd-application.yaml` - Application

**Rationale:** ArgoCD is operational at this point, allowing safe deployment of ArgoCD-managed resources.

### **Sync-Wave -30: Independent Custom Resources**

Custom resources that do not depend on storage infrastructure or policy execution.

**Resources:**

- `optional/lso/lsoLocalVolume.yaml` - LocalVolume
- `required/acm/acmMCE.yaml` - MultiClusterEngine
- `required/acm/acmMCH.yaml` - MultiClusterHub  
- `required/acm/acmMirrorRegistryCM.yaml` - ConfigMap (depends on multicluster-engine namespace creation by MCE)
- `required/acm/acmProvisioning.yaml` - Provisioning
- `optional/odf-internal/storageCluster.yaml` - StorageCluster (creates storage infrastructure)
- `optional/logging/clusterLogForwarder.yaml` - ClusterLogForwarder (configures log forwarding)
- `optional/backup-recovery/dataProtectionApplication.yaml` - DataProtectionApplication
- `optional/cert-manager/certManagerClusterIssuer.yaml` - ClusterIssuer
- `optional/cert-manager/consoleCertificate.yaml` - Certificate
- `optional/cert-manager/downloadsCertificate.yaml` - Certificate
- `optional/cert-manager/oauthServiceCertificate.yaml` - Certificate

**Rationale:** These resources can be deployed independently without waiting for storage provisioning or policy execution.

### **Sync-Wave -25: Policies and Validation**

All ACM policies for configuration, node preparation, and infrastructure validation that must complete before dependent services deploy.

**Resources:**

**ACM Pull Secret Policies:**

- `required/acm/pullSecretPlacement.yaml` - Placement
- `required/acm/pullSecretMCSB.yaml` - ManagedClusterSetBinding
- `required/acm/pullSecretPolicy.yaml` - Policy**
- `required/acm/pullSecretPlacementBinding.yaml` - PlacementBinding

**ACM Thanos Secret Policies:**

- `required/acm/thanosSecretPlacement.yaml` - Placement
- `required/acm/thanosSecretPlacementBinding.yaml` - PlacementBinding

**GitOps Policies:**

- `required/gitops/addPluginsPolicy.yaml` - Policy** components (without namespace)

**Backup Policies:**

- `optional/backup-recovery/policy-backup.yaml` - Policy

**Storage Validation Policies:**

- `optional/odf-internal/odfReady.yaml` - Policy**, Placement, PlacementBinding (ODF readiness validation)

**Rationale:** All policy-based configurations and validations deploy together after infrastructure components are established. This unified phase handles cluster configuration, security setup, and infrastructure readiness verification before storage-dependent services deploy.

**Note:** The resources marked with ** are the most time-consuming in this wave.

### **Sync-Wave -10: Storage-Dependent Services**

Services and resources that require validated, ready storage infrastructure.

**Resources:**

- `required/acm/acmAgentServiceConfig.yaml` - AgentServiceConfig (creates PVCs for database, filesystem, image storage)
- `required/acm/observabilityOBC.yaml` - ObjectBucketClaim (requires object storage)
- `optional/backup-recovery/objectBucketClaim.yaml` - ObjectBucketClaim (requires object storage)
- `required/acm/observabilityMCO.yaml` - MultiClusterObservability (requires storage class for metrics)
- `optional/backup-recovery/backupSchedule.yaml` - BackupSchedule (requires storage for backups)
- `optional/backup-recovery/restore.yaml` - Restore (requires storage for restore operations)
- `required/acm/thanosSecretPolicy.yaml` - Policy (depends on observability-obc storage)
- `required/acm/acmPerfSearch.yaml` - Search (requires database storage)

**Rationale:** These services create storage claims or depend on storage infrastructure being validated and ready for use.

### **Sync-Wave 100: ZTP Components**

Zero Touch Provisioning installation components deployed after the platform is fully operational.

**Resources:**

**ZTP AppProjects:**

- `required/gitops/ztp-installation/app-project.yaml` - AppProject
- `required/gitops/ztp-installation/policies-app-project.yaml` - AppProject

**ZTP Applications:**

- `required/gitops/ztp-installation/clusters-app.yaml` - Application/Namespace
- `required/gitops/ztp-installation/policies-app.yaml` - Application/Namespace

**ZTP Role Bindings:**

- `required/gitops/ztp-installation/gitops-cluster-rolebinding.yaml` - ClusterRoleBinding
- `required/gitops/ztp-installation/gitops-policy-rolebinding.yaml` - ClusterRoleBinding

**Rationale:** ZTP components represent the final deployment phase when all platform services are ready.

## Design Principles

**Deterministic Ordering:** Predictable, dependency-aware deployment with clear failure boundaries.

**Kubernetes Native:** Follows kubectl apply order (Namespaces → RBAC → Storage → ConfigMaps/Secrets → Custom Resources).

**Operational Benefits:** Easy troubleshooting, simple maintenance, scalable structure.

## Validation

✅ Registry → Namespaces → Operators → ArgoCD → Independent → Policies & Validation → Storage-Dependent → ZTP

## Implementation

**8 Sync-Waves** | **68 Resources** | **All Dependencies Ordered**

Provides robust, maintainable foundation for deterministic roll outs of telco-hub deployments.
