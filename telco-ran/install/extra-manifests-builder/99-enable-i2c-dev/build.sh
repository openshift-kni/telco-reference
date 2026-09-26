#!/bin/bash

MCPROLE=${MCPROLE:-master}

# MachineConfig to enable i2c-dev module
# This allows PTP operator to read precision timing oscillator model on Intel GNRD (Granite Rapids D) platform

cat << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 99-enable-i2c-dev-${MCPROLE}
  labels:
    machineconfiguration.openshift.io/role: ${MCPROLE}
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
        - contents:
            source: data:text/plain;base64,aTJjLWRldg==
          mode: 0644
          overwrite: true
          path: /etc/modules-load.d/i2c-dev.conf
EOF

