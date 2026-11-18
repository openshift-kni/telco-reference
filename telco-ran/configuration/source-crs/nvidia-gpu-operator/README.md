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

For RAN, enable the commented `nvidia-video-workaround` ConfigMap generator in `install/clusterinstance/kustomization.yaml` and its `extraManifestsRefs` entry in the applicable ClusterInstance example. Set the ConfigMap namespace to the cluster namespace and include only the MachineConfig roles needed by GPU nodes.

For Core, create a separate `nvidia-video-workaround` ConfigMap from the matching `50-nvidia-video-master.yaml` or `50-nvidia-video-worker.yaml` files under `install/extra-manifests/optional/nvidia-gpu-operator/`, then enable its commented reference in `install/example-standard-clusterinstance.yaml`. These MachineConfigs are install-only; do not add them to the baseline policy.

## Optional GPUDirect RDMA PCIe configuration

The optional `99-nvidia-dmabuf-pcie-master.yaml` and `99-nvidia-dmabuf-pcie-worker.yaml` MachineConfigs provide the validated IOMMU passthrough and ACS redirect settings for the hardware/topology described in their comments. They are separate from the video-module workaround and disabled by default. Verify the GPU/NIC PCIe path and vendor-recommended ACS configuration before enabling them; the bridge ID matches all devices with that ID and is not a universal ConnectX-8 requirement. Applying these settings to existing nodes triggers a rollout/reboot and changes IOMMU grouping.

For RAN, enable the commented `nvidia-dmabuf-pcie` ConfigMap generator in `install/clusterinstance/kustomization.yaml` and its `extraManifestsRefs` entry in the applicable ClusterInstance example. Use the target cluster namespace and include only the roles hosting the target GPU and NIC devices. For Core, create a separate `nvidia-dmabuf-pcie` ConfigMap from the role-specific files under `install/extra-manifests/optional/nvidia-gpu-operator/` and enable its commented reference in `install/example-standard-clusterinstance.yaml`. These MachineConfigs are install-only; do not add them to the baseline policy.

Validate host-memory and GPU-memory RDMA with payload checking, then check for PCIe/NIC errors. The existing validation covers same-node DMA-BUF RDMA with IOMMU passthrough; translated IOMMU mode, external-fabric traffic, and performance qualification are not established by this example.
