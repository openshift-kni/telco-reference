#!/bin/bash

MCPROLE=${MCPROLE:-master}

# The SCTP machine config just asks for the sctp kernel module to be loaded

echo "\
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
          mode: 420
          overwrite: true
          contents:
            source: data:,
        - path: /etc/modules-load.d/sctp-load.conf
          mode: 420
          overwrite: true
          contents:
            source: data:,sctp"
