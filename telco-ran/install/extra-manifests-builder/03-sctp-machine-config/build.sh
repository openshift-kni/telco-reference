#!/bin/bash

MCPROLE=${MCPROLE:-master}

# The SCTP machine config just asks for the sctp kernel module to be loaded

echo "\
# Follows OpenShift Advanced networking: Enabling SCTP; role is selected below.
# https://github.com/openshift/openshift-docs/blob/main/modules/nw-sctp-enabling.adoc
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: load-sctp-module-${MCPROLE}
  labels:
    machineconfiguration.openshift.io/role: ${MCPROLE}
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
        - path: /etc/modprobe.d/sctp-blacklist.conf
          mode: 0644
          overwrite: true
          contents:
            source: data:,
        - path: /etc/modules-load.d/sctp-load.conf
          mode: 0644
          overwrite: true
          contents:
            source: data:,sctp"
