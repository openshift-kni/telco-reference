# NVIDIA GPU Operator

This set of configuration CRs are intended for setting up the Nvidia GPU operator on a compatible GPU accelerated node

The installation uses package `gpu-operator-certified`, channel `v26.7`, starting CSV `gpu-operator-certified.v26.7.2`

Pre-requisites to this setup includes the Red Hat NFD deployement and mirroring the certified catalog using the provided Hub image set configuration.

NVIDIA GPU Operator container images are not signed, which can cause signature-related failures when mirroring with `oc-mirror` v2. Follow the [Red Hat procedure for disabling signature verification for the affected mirror source](https://access.redhat.com/solutions/7139982).

## Precompiled driver

The sample ClusterPolicy selects precompiled open kernel modules, disables Driver Toolkit compilation, and enables CDI. Replace `spec.driver.repository` and `spec.driver.version` with a verified mirrored driver. A mirror of the operator bundle does not include Red Hat-provided precompiled drivers automatically. Verify the exact target kernel, architecture, page size, GPU support, and signing requirements for every node and before each kernel upgrade.

GPU Operator 26.7.2 was validated on OpenShift 5.0.0 ARM64 with staging `registry.stage.redhat.io/nvidia/gpu-driver-rhel10:595.91.07-6.12.0-211.69.1.el10_2.aarch64_64k-rhcos5.0`.

## Optional ACPI video dependency workaround

The tested precompiled image declares `depends=video,nvidia` in nvidia-modeset.ko, but its modules.dep omits video. On the lab node this caused unknown ACPI backlight symbols. Loading the existing host video module resolved driver initialization and nvidia-smi succeeded. Optional master and worker MachineConfigs persist video in `/etc/modules-load.d/nvidia-video.conf`. Enable only the roles needed by affected GPU nodes, after confirming the host module exists. Remove the workaround when the driver image correctly resolves its dependency.

For RAN, enable the commented `nvidia-video-workaround` ConfigMap generator in `install/clusterinstance/kustomization.yaml` and its `extraManifestsRefs` entry in the applicable ClusterInstance example. Set the ConfigMap namespace to the cluster namespace and include only the MachineConfig roles needed by GPU nodes.

For Core, enable the matching optional MachineConfig entries in the baseline policy.
