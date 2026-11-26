# NVIDIA GPU Operator

These configuration CRs install the NVIDIA GPU Operator on a compatible GPU-accelerated node.

Prerequisites include a shared Red Hat NFD deployment and mirroring the required certified catalog content. For GPUDirect RDMA, follow the upstream vendor setup instructions for your hardware, including any PCIe ACS requirements.

NVIDIA GPU Operator container images are not signed, which can cause signature-related failures when mirroring with `oc-mirror` v2. Follow the [Red Hat procedure for disabling signature verification for the affected mirror source](https://access.redhat.com/solutions/7139982).

## Sample ClusterPolicy

[`ClusterPolicy.yaml`](ClusterPolicy.yaml) is an illustrative operand configuration, not an enforced reference requirement. Customers and partners own its contents and select component versions with NVIDIA. The ACM PolicyGenerator includes a commented example for both operand CRs. Customize them before enabling the example after the operator and its CRDs are ready. Kube-compare excludes the operand samples.

## Precompiled driver

Use the `NvidiaDriver.yaml` and `ClusterPolicy.yaml` samples together. The driver resource selects precompiled open kernel modules. Set its node selector, repository, image, and version for your deployment. ClusterPolicy enables CDI and continues to manage the other operands. A mirror of the operator bundle does not include Red Hat-provided precompiled drivers automatically. Verify the exact target kernel, architecture, page size, GPU support, and signing requirements for every node and before each kernel upgrade.

## Optional ACPI video dependency workaround

The missing `video` module dependency is tracked in [OCPBUGS-141910](https://redhat.atlassian.net/browse/OCPBUGS-141910).

The tested precompiled image declares `depends=video,nvidia` in nvidia-modeset.ko, but its modules.dep omits video. On the lab node this caused unknown ACPI backlight symbols. Loading the existing host video module resolved driver initialization and nvidia-smi succeeded. Optional master and worker MachineConfigs persist video in `/etc/modules-load.d/nvidia-video.conf`. Enable only the roles needed by affected GPU nodes, after confirming the host module exists. Remove the workaround when the driver image correctly resolves its dependency.

Uncomment the video MachineConfig entries for the affected node roles in the extra-manifests ConfigMap generator in `install/clusterinstance/kustomization.yaml`.
