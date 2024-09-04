Some previous configured components:
   * ACM requires storage configured in order to use the AgentServiceConfig
   * MCO requires a pull-secret imported on the NS `open-cluster-management-observability` as a Secret.
   * MCO requires an S3 compatible bucket storage with the connectivity info as:

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
      bucket:  ""
      endpoint: ""
      insecure: true
      access_key: ""
      secret_key: ""
```
