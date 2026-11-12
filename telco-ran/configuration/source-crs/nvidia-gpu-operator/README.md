# NVIDIA GPU Operator

The optional installation uses package `gpu-operator-certified`, channel `v26.7`, starting CSV `gpu-operator-certified.v26.7.2`, and Manual InstallPlan approval. Use the existing ACM inform policies and a TALM CGU to approve and remediate installation. The certified package is currently available from the production OpenShift 4.22 catalog; this does not establish OpenShift 5.1 support.

Mirror the certified catalog using the Hub image set configuration. Reuse an existing certified CatalogSource or enable the optional shared certified CatalogSource. Replace its registry image placeholder and configure registry trust, credentials, and mirror rules from the actual mirror output. Do not install a second NFD instance: use the shared Red Hat NFD deployment.

NVIDIA GPU Operator container images are not signed, which can cause signature-related failures when mirroring with `oc-mirror` v2. Follow the [Red Hat procedure for disabling signature verification for the affected mirror source](https://access.redhat.com/solutions/7139982).

Enable the installation entries in the common policy and the ClusterPolicy entry in the applicable SNO, 3-node, or Standard group policy. Core has equivalent optional baseline and upgrade entries. Apply prerequisites before the operand policy. The examples remain disabled by default.

## Precompiled driver

The sample ClusterPolicy selects precompiled open kernel modules, disables Driver Toolkit compilation, and enables CDI. Replace `spec.driver.repository` and `spec.driver.version` with a verified mirrored driver. A mirror of the operator bundle does not include Red Hat-provided precompiled drivers automatically. Verify the exact target kernel, architecture, page size, GPU support, and signing requirements for every node and before each kernel upgrade.

The lab used GPU Operator 26.7.2 on OpenShift 5.0.0-rc.7 ARM64 with staging `registry.stage.redhat.io/nvidia/gpu-driver-rhel10:610.57.04-6.12.0-211.66.1.el10_2.aarch64_64k-rhel10.2`. The operator constructs a `rhel10` suffix for this node, so the verified image was mirrored under the corresponding `...-rhel10` tag with identical image digests. Do not assume this image matches a different kernel or OpenShift 5.1 node.

## Optional ACPI video dependency workaround

The tested precompiled image declares `depends=video,nvidia` in nvidia-modeset.ko, but its modules.dep omits video. On the lab node this caused unknown ACPI backlight symbols. Loading the existing host video module resolved driver initialization and nvidia-smi succeeded. Optional master and worker MachineConfigs persist video in `/etc/modules-load.d/nvidia-video.conf`. Enable only the roles needed by affected GPU nodes, after confirming the host module exists. Remove the workaround when the driver image correctly resolves its dependency.

The MachineConfig can trigger node disruption or a reboot. The lab rollout created a new desired configuration, after which the SNO API became unreachable. Post-reboot recovery, module persistence, and GPU readiness remain unverified. This is not a validated boot-persistence solution yet.

## Verification

Check CSV Succeeded, operator deployment availability, and clusterpolicies.nvidia.com Established. For the GPU stack, require ClusterPolicy ready, driver/toolkit/device-plugin readiness, successful CUDA validation and nvidia-smi, and allocatable nvidia.com/gpu. Verify MCP convergence, node readiness, modules-load file contents, and module/GPU recovery after reboot. The lab passed full GPU stack readiness before the persistent MachineConfig rollout.
