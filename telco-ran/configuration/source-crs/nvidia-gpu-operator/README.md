# NVIDIA GPU Operator

These configuration CRs install the NVIDIA GPU Operator on a compatible GPU-accelerated node.

Prerequisites include a shared Red Hat NFD deployment and mirroring the required certified catalog content.

NVIDIA GPU Operator container images are not signed, which can cause signature-related failures when mirroring with `oc-mirror` v2. Follow the [Red Hat procedure for disabling signature verification for the affected mirror source](https://access.redhat.com/solutions/7139982).

## Sample ClusterPolicy

[`ClusterPolicy.yaml`](ClusterPolicy.yaml) is an illustrative operand configuration, not an enforced reference requirement. Customers and partners own its contents and select component versions with NVIDIA. It is not included in the baseline/group policies or kube-compare validation. Copy and customize it for your deployment after installing the operator.

## Precompiled driver

The sample ClusterPolicy selects precompiled open kernel modules, disables Driver Toolkit compilation, and enables CDI. Replace `spec.driver.repository` and `spec.driver.version` with a verified mirrored driver. A mirror of the operator bundle does not include Red Hat-provided precompiled drivers automatically. Verify the exact target kernel, architecture, page size, GPU support, and signing requirements for every node and before each kernel upgrade.

## Optional ACPI video dependency workaround

The missing `video` module dependency is tracked in [OCPBUGS-141910](https://redhat.atlassian.net/browse/OCPBUGS-141910).

The tested precompiled image declares `depends=video,nvidia` in nvidia-modeset.ko, but its modules.dep omits video. On the lab node this caused unknown ACPI backlight symbols. Loading the existing host video module resolved driver initialization and nvidia-smi succeeded. Optional master and worker MachineConfigs persist video in `/etc/modules-load.d/nvidia-video.conf`. Enable only the roles needed by affected GPU nodes, after confirming the host module exists. Remove the workaround when the driver image correctly resolves its dependency.

Enable the commented `nvidia-video-workaround` ConfigMap generator in `install/clusterinstance/kustomization.yaml` and its `extraManifestsRefs` entry in the applicable ClusterInstance example. Set the ConfigMap namespace to the cluster namespace and include only the MachineConfig roles needed by affected GPU nodes.

## Optional GPUDirect RDMA PCIe configuration

The optional `99-nvidia-dmabuf-pcie-master.yaml` and `99-nvidia-dmabuf-pcie-worker.yaml` MachineConfigs provide the validated IOMMU passthrough and ACS redirect settings for the hardware/topology described in their comments. They are separate from the video-module workaround and disabled by default. Confirm that the GPU/NIC topology requires ACS redirect changes before enabling these settings. The kernel argument targets PCIe bridges with ID `15b3:197c`, not the ConnectX-8 NIC itself. Follow the platform vendor's ACS recommendations. Applying these settings to existing nodes triggers a rollout/reboot and changes IOMMU grouping.

Enable the commented `nvidia-dmabuf-pcie` ConfigMap generator in `install/clusterinstance/kustomization.yaml` and its `extraManifestsRefs` entry in the applicable ClusterInstance example. Set the ConfigMap namespace to the cluster namespace and include only the roles hosting the target GPU and NIC devices.
