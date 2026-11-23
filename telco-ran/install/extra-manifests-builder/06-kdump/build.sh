#!/bin/bash

MCPROLE=${MCPROLE:-master}

# kdump MachineConfig is to enable the kdump.service and add it in the kernel command line
# Exclude idxd from the kdump initramfs as a workaround for RHEL-288724.

# Use a percent-encoded data URL to keep the kdump settings readable in the manifest.
KDUMP_CONFIG=$(sed -e 's/%/%25/g' -e 's/#/%23/g' -e 's/?/%3F/g' \
    -e 's/ /%20/g' -e 's/"/%22/g' -e 's/$/%0A/' kdump.conf | tr -d '\n')

echo "\
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: ${MCPROLE}
  name: 06-kdump-enable-${MCPROLE}
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
        # Workaround for https://redhat.atlassian.net/browse/RHEL-288724
        # Remove the idxd exclusion once the fix is merged in RHEL.
        - path: /etc/kdump.conf
          mode: 420
          overwrite: true
          contents:
            source: data:text/plain;charset=utf-8,${KDUMP_CONFIG}
    systemd:
      units:
      - enabled: true
        name: kdump.service
  kernelArguments:
    - crashkernel=676M"
