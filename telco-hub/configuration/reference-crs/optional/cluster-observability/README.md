# Cluster Observability Operator Configuration

This directory contains optional configurations for the Cluster Observability Operator (COO), which extends the OpenShift web console with monitoring UI plugins including RHACM alert integration and incident detection.

## Overview

These manifests:
- Install the Cluster Observability Operator in its recommended namespace
- Enable the Monitoring UIPlugin with RHACM Observability backends

## Files

### Operator Installation
- `cooNS.yaml` - Creates the `openshift-cluster-observability-operator` namespace with cluster monitoring enabled
- `cooOperatorGroup.yaml` - Creates the OperatorGroup (all-namespaces mode)
- `cooSubscription.yaml` - Installs the Cluster Observability Operator from the disconnected catalog

### UI Plugin
- `cooUIPlugin.yaml` - Configures the Monitoring UIPlugin to enable the Perses Dashboard

## Prerequisites

- RHACM Observability must be deployed (required ACM components in this reference)
- Mirror `cluster-observability-operator` in the disconnected image set configuration

## Deployment Order

1. Deploy operator installation files (NS, OperatorGroup, Subscription)
2. Wait for the operator to be ready
3. Deploy the UIPlugin CR


## References

- [Installing the Cluster Observability Operator](https://docs.redhat.com/en/documentation/red_hat_openshift_cluster_observability_operator/1-latest/html/installing_red_hat_openshift_cluster_observability_operator/index)
- [Monitoring UI plugin](https://docs.redhat.com/en/documentation/red_hat_openshift_cluster_observability_operator/1-latest/html/ui_plugins_for_red_hat_openshift_cluster_observability_operator/monitoring-ui-plugin)
