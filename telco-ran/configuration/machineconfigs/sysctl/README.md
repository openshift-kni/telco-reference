# MachineConfigs in `machineconfigs/sysctl`

This directory contains MachineConfig YAMLs that configure kernel sysctl parameters for RHCOS nodes. Each file is listed below with a summary and performance note.

---

## [75-rhcos4-etc_sysctl.d_75-sysctl_kernel_dmesg_restrict.conf-combo.yaml](./75-rhcos4-etc_sysctl.d_75-sysctl_kernel_dmesg_restrict.conf-combo.yaml)
**Purpose:** Sets `kernel.dmesg_restrict=1` to restrict access to kernel logs (dmesg) to root only.
**Potential Performance Impact:** Negligible.

## [75-rhcos4-etc_sysctl.d_75-sysctl_kernel_randomize_va_space.conf-combo.yaml](./75-rhcos4-etc_sysctl.d_75-sysctl_kernel_randomize_va_space.conf-combo.yaml)
**Purpose:** Sets `kernel.randomize_va_space=2` to enable full Address Space Layout Randomization (ASLR) for process memory.
**Potential Performance Impact:** Negligible for most workloads; may slightly impact debugging or legacy applications.

## [75-rhcos4-etc_sysctl.d_75-sysctl_kernel_unprivileged_bpf_disabled.conf-combo.yaml](./75-rhcos4-etc_sysctl.d_75-sysctl_kernel_unprivileged_bpf_disabled.conf-combo.yaml)
**Purpose:** Sets `kernel.unprivileged_bpf_disabled=1` to prevent unprivileged users from loading eBPF programs.
**Potential Performance Impact:** Negligible for most workloads; may impact applications relying on unprivileged eBPF.

## [75-rhcos4-etc_sysctl.d_75-sysctl_kernel_yama_ptrace_scope.conf-combo.yaml](./75-rhcos4-etc_sysctl.d_75-sysctl_kernel_yama_ptrace_scope.conf-combo.yaml)
**Purpose:** Sets `kernel.yama.ptrace_scope=1` to restrict ptrace system call usage for better process isolation.
**Potential Performance Impact:** Negligible for most workloads; may impact debugging tools.

## [75-rhcos4-etc_sysctl.d_75-sysctl_net_core_bpf_jit_harden.conf-combo.yaml](./75-rhcos4-etc_sysctl.d_75-sysctl_net_core_bpf_jit_harden.conf-combo.yaml)
**Purpose:** Sets `net.core.bpf_jit_harden=2` to harden the BPF JIT compiler against attacks.
**Potential Performance Impact:** Negligible for most workloads; may slightly increase CPU usage for heavy BPF workloads.

---

## General Notes
- **Testing:** Always test MachineConfigs in a staging environment before applying to production, especially for performance-sensitive workloads.
- **Monitoring:** After applying, monitor kernel logs and application behavior for unexpected issues.

*Last updated: June 2, 2025*
