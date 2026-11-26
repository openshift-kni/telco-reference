#!/bin/bash

MCPROLE=${MCPROLE:-master}

cat <<EOF
# Optional workaround for precompiled images whose modules.dep omits the video dependency.
---
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 50-nvidia-video-${MCPROLE}
  labels:
    machineconfiguration.openshift.io/role: ${MCPROLE}
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - path: /etc/modules-load.d/nvidia-video.conf
        mode: 420
        overwrite: true
        contents:
          source: data:,video%0A
EOF
