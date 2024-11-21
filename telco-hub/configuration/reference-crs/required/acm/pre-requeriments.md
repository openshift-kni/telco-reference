
# Previous configured components

   * ACM requires ODF configured in order to create the storage for the AgentServiceConfig. Two PVs will be created/required.
   * MCO requires an S3 compatible bucket storage. The connection to the storage is contained into a Secret, created on the NS `open-cluster-management-observability`. Example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket:  "my-bucket-observability-67016e5a-a558-5fc15ee0075c"
      endpoint: "rook-ceph-rgw-ocs-storagecluster-cephobjectstore.openshift-storage.svc"
      insecure: true
      access_key: "F37GAMG8...........6NU"
      secret_key: "OylYlj5Y...........iFtTcwoBPF9EdEqSMUF0"
```
If the S3 endpoint uses the HTTPS (443) port the following config must be used to allow unknown CAs:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: s3
    config:
      bucket:  "my-bucket-observability-67016e5a-a558-5fc15ee0075c"
      endpoint: "s3.openshift-storage.svc:443"
      access_key: "F37GAMG8...........6NU"
      secret_key: "OylYlj5Y...........iFtTcwoBPF9EdEqSMUF0"
      http_config:
        insecure_skip_verify: true
```
   * MCO requires a pull-secret imported on the Namespace `open-cluster-management-observability` as a Secret. Example:
  
```yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    cluster.open-cluster-management.io/backup: ""
  name: multiclusterhub-operator-pull-secret
  namespace: open-cluster-management-observability
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: 
  <REDACTED>
```
