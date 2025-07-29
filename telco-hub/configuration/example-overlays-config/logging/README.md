# Logging Overlay Configuration Example

Example overlay for customizing the telco-hub ClusterLogForwarder.

## ClusterLogForwarder Patch

The `cluster-log-forwarder-patch.yaml` customizes (not limited to):

1. **Kafka endpoint**: Hub-specific server with cluster claim templating
2. **Labels**: Hub-specific OpenShift labels

## Testing

```bash
# Test the overlay
kubectl kustomize telco-hub/configuration/example-overlays-config/logging/

# Apply the overlay
kubectl apply -k telco-hub/configuration/example-overlays-config/logging/
```

## Key Configuration

- **Kafka URL**: Update `jumphost.inbound.lab:9092` to your Kafka broker
- **Labels**: Customize `openshiftLabels` for your environment
