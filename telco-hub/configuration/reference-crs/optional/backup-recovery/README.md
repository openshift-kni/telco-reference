# Backup and Recovery Process Overview

## Purpose

The purpose of this procedure is to demonstrate how to perform disaster recovery for Red Hat Advanced Cluster Management for Hub cluster failures. This process covers backup and recovery operations, which rely on the OADP Operator to utilize Velero resources.

## Prerequisites

* The cluster-backup component is enabled in MultiClusterHub CR. This will automatically install the OADP operator in namespace *open-cluster-management-backup*.
* An external AWS S3 compatible storage is required as backup location. It can be AWS S3, Red Hat Ceph Object Gateway, Red Hat Openshift Data Foundation(located outside the Hub cluster), or MinIO.

## Backup Process

#### 1-Secret for S3 storage

Update Access Key and Secret Access Key for the external S3 compatible storage in *s3storageSecret.yaml*, and create Secret on the active and passive hub clusters.

```bash
oc apply -f s3storageSecret.yaml
```
This Secret is referenced in the spec.backupLocations.credential block of the DataProtectionApplication CR when you install the Data Protection Application.


#### 2-DataProtectionApplication CR
Update the URL of external S3 compatible object storage that you are using to store backups in *dataProtectionApplication.yaml*, and create the DataProtectionApplication resource on the active and passive hub clusters.

```bash
oc apply -f dataProtectionApplication.yaml
```

Ensure the S3 bucket is reachable by checking the BackupStorageLocation resource is in phase ‘Available’.

```bash
oc get backupstoragelocation  -n open-cluster-management-backup hub-backup-1 -o json | jq .status
{
  "lastSyncedTime": "2026-09-21T18:20:07Z",
  "lastValidationTime": "2026-09-21T18:20:06Z",
  "phase": "Available"
}
```

#### 3-BackupSchedule CR
Update the backup scheduling interval and define the expiration time for scheduled backups in *backupSchedule.yaml*, then create a BackupSchedule CR to schedule backups on the active hub cluster.

Before creating the backup ensure that all BMH are labeled correctly to avoid issue when restoration is done. Below Policy can help achieve that:

```bash
oc apply -f policy-backup.yaml
```

Create the BackupSchedule CR to schedule the backups.

```bash
oc apply -f backupSchedule.yaml
```

Check the backups are created and managed by OADP.

```bash
oc get backupschedules.cluster.open-cluster-management.io 
NAME              PHASE     MESSAGE
schedule-drtest   Enabled   Velero schedules are enabled
```

```bash
oc get backup -A
NAMESPACE                        NAME                                            AGE
open-cluster-management-backup   acm-credentials-schedule-20260918000003         4d17h
open-cluster-management-backup   acm-managed-clusters-schedule-20260918000003    4d17h
open-cluster-management-backup   acm-resources-generic-schedule-20260918000003   4d17h
open-cluster-management-backup   acm-resources-schedule-20260918000003           4d17h
open-cluster-management-backup   acm-validation-policy-schedule-20260918000003   4d17h
```


## Recovery Process

#### Note: For disaster recovery simulation test, shut down the active hub cluster or pause BakcupSchedule resource on the active hub cluster before running restore operations on the passive hub cluster.

#### 1-Prepare the Passive Hub cluster
Before performing a recovery operation on a Passive Hub cluster, the same version operators as the Active Hub cluster must be installed on that cluster. 

You need to install the Red Hat Advanced Cluster Management Operator in the same namespace as the Active Hub cluster, create a MultiClusterHub resource with the same components enabled, and then create a DataProtectionApplication resource with the same storage location that the Active Hub cluster previously used when backing up data.


#### 2-Restore CR
In a typical restore situation, the Active Hub cluster becomes unavailable, and you need to run the restore operations on the Passive Hub cluster. In this case, the restore operation runs on a different hub cluster than where the backup is created.

Create a restore.cluster.open-cluster-management.io resource on the Passive Hub cluster to initiate a restore operation.

```bash
oc apply -f restore.yaml
```

Check the restore operation status.
```bash
oc get restores.cluster.open-cluster-management.io -A
NAMESPACE                        NAME          PHASE      MESSAGE
open-cluster-management-backup   restore-hub   Finished   All Velero restores have run successfully
```



Back to [Hub Cluster Setup](../../../../README.md).
