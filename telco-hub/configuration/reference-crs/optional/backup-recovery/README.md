#Backup and Recovery process CR are documented here

###Purpose 

The purpose of this procedure is to show how to backup the Hub cluster CRs and Recover in case of failure. It can either be in an active-passive Architecture or just a simple hub. 

### Prerequisites 

* OADP operator enabled through the MulticlusterHub CR ( RHACM)
* An S3 Bucket ideally you want an s3 endpoint that is external to the hub. The purpose of this s3 bucket is to be used as a backup storage location
for the multicluster-engine deployment of OADP. 

### Backup Process

#### 1-Create OBC and get the secret Information 

```bash
$ oc apply -f objectBucketClaim.yaml

```

```yaml
$ oc get secret -n open-cluster-management-backup backup -o yaml

apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: xxxxxxxxxxxxx
  AWS_SECRET_ACCESS_KEY: xxxxxxxxx
kind: Secret
metadata:
  creationTimestamp: "2024-11-12T17:39:47Z"
  finalizers:
  - objectbucket.io/finalizer
  labels:
    app: noobaa
    bucket-provisioner: openshift-storage.noobaa.io-obc
    noobaa-domain: openshift-storage.noobaa.io
  name: backup
  namespace: open-cluster-management-backup
type: Opaque

```

##### decode the key Id and the AW secret access key to create the velero secret 

#### 2- Create velero secret

```bash
$ cat credentials-velero 
[default]
aws_access_key_id=xxxxxxxxxxxxxxx
aws_secret_access_key=xxxxxxxxxxxxxx
```

```bash
oc create secret generic cloud-credentials -n open-cluster-management-backup --from-file cloud=credentials-velero

```
#### 3- Get the  s3 route for your bucket. it  can be retrieved with the step below:

```bash
  oc get routes -n openshift-storage | grep s3 | awk {'print $2'}

```
#### 4-  Create the dataprotection application backup

```bash
$ oc apply -f dataProtectionApplication.yaml
```

#### Ensure the S3 bucket is reachable by checking the BackupStorageLocation resource is in
phase ‘Available’

```bash
oc get backupstoragelocation  -n open-cluster-management-backup hubtest-1 -o json | jq .status
{
  "lastSyncedTime": "2024-11-12T18:31:53Z",
  "lastValidationTime": "2024-11-12T18:32:03Z",
  "phase": "Available"
}


```

### Before creating the backup ensure that all BMH are labeled correctly to avoid issue when restoration is done. Below Policy can help achieve that.

```bash

$ oc apply -f policy-backup.yaml

```

#### create the backup job to schedule the backup

```bash
$ oc apply -f backupSchedule.yaml
```

#### check the backup 

```bash
oc get backupschedules.cluster.open-cluster-management.io 
NAME              PHASE     MESSAGE
schedule-drtest   Enabled   Velero schedules are enabled
 
```
```bash
oc get backup -A
NAMESPACE                        NAME                                            AGE
open-cluster-management-backup   acm-credentials-schedule-20241112183617         80s
open-cluster-management-backup   acm-managed-clusters-schedule-20241112183617    80s
open-cluster-management-backup   acm-resources-generic-schedule-20241112183617   80s
open-cluster-management-backup   acm-resources-schedule-20241112183617           80s
open-cluster-management-backup   acm-validation-policy-schedule-20241112183617   80s
```

## To restore  a HUB cluster below ressource can be used
```bash
$ oc apply -f backupSchedule.yaml
```
