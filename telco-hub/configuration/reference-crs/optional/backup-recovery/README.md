# Backup and Recovery process CR are documented here

### Purpose 

The purpose of this procedure is to show how to backup the Hub cluster CRs and  Recover in case of failure. It can either be in an active-passive Architecture or just a simple hub. 

### Prerequisites 

* OADP operator enabled through the MulticlusterHub CR ( RHACM)
* An S3 Bucket ideally you want an s3 endpoint that is external to the hub. The purpose of this s3 bucket is to be used as a backup storage location
for the multicluster-engine deployment of OADP. 

### Backup Process

#### 1-  Create OBC  and get the secret Information 

```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: backup
  namespace: default
spec:
  generateBucketName: backup
  storageClassName: openshift-storage.noobaa.io
```
```bash

oc get obc
```

```yaml
$ oc get secret -n default
NAME     TYPE     DATA   AGE
backup   Opaque   2      45m
[root@rack1-jumphost 20241112-13:25:01]$ oc get secret -n default backup -o yaml
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
  namespace: default
  ownerReferences:
  - apiVersion: objectbucket.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: ObjectBucketClaim
    name: backup
    uid: d5569ae9-5d57-4abd-99cd-f7f328c358c9
  resourceVersion: "227605111"
  uid: 73aebe24-1751-4fdd-a5f2-7a10be369892
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

```yaml
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: hub-backup
  namespace: open-cluster-management-backup
spec:
  backupLocations:
    - velero:
        config:
          profile: default
          region: us-east-1
          s3ForcePathStyle: 'true'
          s3Url: # your S3 endpoint
          insecureSkipTLSVerify: "true"
        credential:
          key: cloud
          name: cloud-credentials
        default: true
        objectStorage:
          bucket: backup-05a35399-bc56-46ac-99bc-a50dd0ad8a1e
          prefix: velero
        provider: aws
  configuration:
    restic:
      enable: true
    velero:
      defaultPlugins:
        - openshift
        - aws
        - kubevirt
  snapshotLocations:
    - velero:
        config:
          profile: default
          region: minio
        provider: aws

```

## validation 
#### Confirm the health of the DPA by checking if the status of the DPA resource is ‘Reconciled’

```bash
oc get dpa -A -o yaml
apiVersion: v1
items:
- apiVersion: oadp.openshift.io/v1alpha1
  kind: DataProtectionApplication
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"oadp.openshift.io/v1alpha1","kind":"DataProtectionApplication","metadata":{"annotations":{},"name":"hubtest","namespace":"open-cluster-management-backup"},"spec":{"backupLocations":[{"velero":{"config":{"insecureSkipTLSVerify":"true","profile":"default","region":"us-east-1","s3ForcePathStyle":"true","s3Url":"https://s3-openshift-storage.apps.hubcluster-1.hubcluster-1.lab.eng.cert.redhat.com"},"credential":{"key":"cloud","name":"cloud-credentials"},"default":true,"objectStorage":{"bucket":"backup-05a35399-bc56-46ac-99bc-a50dd0ad8a1e","prefix":"velero"},"provider":"aws"}}],"configuration":{"restic":{"enable":true},"velero":{"defaultPlugins":["openshift","aws","kubevirt"]}},"snapshotLocations":[{"velero":{"config":{"profile":"default","region":"minio"},"provider":"aws"}}]}}
    creationTimestamp: "2024-11-12T18:04:28Z"

.........
.........
  status:
    conditions:
    - lastTransitionTime: "2024-11-12T18:04:28Z"
      message: Reconcile complete
      reason: Complete
      status: "True"
      type: Reconciled
kind: List
metadata:

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

### Before creating the backup ensure that all BMH are labeled correctly to avoid issue when restoration is done

```yaml
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: bmh-cluster-activation-label
  annotations:
    policy.open-cluster-management.io/description: Policy used to add the cluster.open-cluster-management.io/backup=cluster-activation label to all BareMetalHost resources
spec:
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: set-bmh-backup-label
        spec:
          object-templates-raw: |
            {{- /* Set cluster-activation label on all BMH resources */ -}}
            {{- $infra_label := "infraenvs.agent-install.openshift.io" }}
            {{- range $bmh := (lookup "metal3.io/v1alpha1" "BareMetalHost" "" "" $infra_label).items }}
                - complianceType: musthave
                  objectDefinition:
                    kind: BareMetalHost
                    apiVersion: metal3.io/v1alpha1
                    metadata:
                      name: {{ $bmh.metadata.name }}
                      namespace: {{ $bmh.metadata.namespace }}
                      labels:
                        cluster.open-cluster-management.io/backup: cluster-activation
            {{- end }}
          remediationAction: enforce
          severity: high
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: bmh-cluster-activation-label-pr
spec:
  predicates:
    - requiredClusterSelector:
        labelSelector:
          matchExpressions:
            - key: name
              operator: In
              values:
                - local-cluster
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: bmh-cluster-activation-label-binding
placementRef:
  name: bmh-cluster-activation-label-pr
  apiGroup: cluster.open-cluster-management.io
  kind: Placement
subjects:
  - name: bmh-cluster-activation-label
    apiGroup: policy.open-cluster-management.io
    kind: Policy
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: default
  namespace: default
spec:
  clusterSet: default
```

#### create the backup job to schedule the backup

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: BackupSchedule
metadata:
  name: schedule-drtest
  namespace: open-cluster-management-backup
spec:
  veleroSchedule: "0 */2 * * *"
  veleroTtl: 120h

```

#### check the backup 

````bash
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
```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Restore
metadata:
  name: restore-acm-bmh
  namespace: open-cluster-management-backup
spec:
  cleanupBeforeRestore: CleanupRestored
  veleroManagedClustersBackupName: latest
  veleroCredentialsBackupName: latest
  veleroResourcesBackupName: latest
  restoreStatus:
    includedResources: 
      - BareMetalHosts 
```
