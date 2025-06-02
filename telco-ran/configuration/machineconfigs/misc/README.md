# MachineConfigs in `machineconfigs/misc`

This directory contains MachineConfig YAMLs that apply audit and authentication rules to RHCOS nodes in a Telco/Edge environment. Each file is listed below with a summary and performance note.

---

## [75-rhcos4-etc_audit_auditd.conf-combo.yaml](./75-rhcos4-etc_audit_auditd.conf-combo.yaml)
**Purpose:** Configures `/etc/audit/auditd.conf` for the Linux Audit daemon (`auditd`).
- Sets log file location, rotation, flush frequency, queue depth, and other auditd parameters.
**Potential Performance Impact:** Auditd introduces some CPU and I/O overhead, especially with frequent log flushing (`freq = 50`) and small log files. For most workloads, these are safe defaults, but tune for high-throughput/low-latency nodes if needed.

## [75-rhcos4-etc_audit_rules.d_75-audit-sysadmin-actions.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-audit-sysadmin-actions.rules-combo.yaml)
**Purpose:** Audits changes to `/etc/sudoers` and `/etc/sudoers.d/` to track sysadmin actions.
**Potential Performance Impact:** Minimal, unless sudoers files are changed very frequently.

## [75-rhcos4-etc_audit_rules.d_75-audit_rules_login_events_faillock.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-audit_rules_login_events_faillock.rules-combo.yaml)
**Purpose:** Audits access to `/var/run/faillock` to track failed login attempts.
**Potential Performance Impact:** Minimal, unless the system is under heavy brute-force login attempts.

## [75-rhcos4-etc_audit_rules.d_75-audit_rules_login_events_lastlog.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-audit_rules_login_events_lastlog.rules-combo.yaml)
**Purpose:** Audits access to `/var/log/lastlog` for login event tracking.
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-audit_rules_login_events_tallylog.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-audit_rules_login_events_tallylog.rules-combo.yaml)
**Purpose:** Audits access to `/var/log/tallylog` for login event tracking.
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-audit_rules_networkconfig_modification.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-audit_rules_networkconfig_modification.rules-combo.yaml)
**Purpose:** Audits changes to network configuration files and system hostname/domain.
**Potential Performance Impact:** Minimal, unless network config files are changed frequently.

## [75-rhcos4-etc_audit_rules.d_75-audit_rules_time_watch_localtime.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-audit_rules_time_watch_localtime.rules-combo.yaml)
**Purpose:** Audits changes to `/etc/localtime` for time-related events.
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-audit_rules_usergroup_modification.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-audit_rules_usergroup_modification.rules-combo.yaml)
**Purpose:** Audits changes to user/group files (`/etc/passwd`, `/etc/group`, etc.).
**Potential Performance Impact:** Minimal, unless user/group changes are frequent.

## [75-rhcos4-etc_audit_rules.d_75-kernel-module-loading-delete.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-kernel-module-loading-delete.rules-combo.yaml)
**Purpose:** Audits use of the `delete_module` syscall (kernel module removal).
**Potential Performance Impact:** Minimal, unless modules are loaded/unloaded frequently.

## [75-rhcos4-etc_audit_rules.d_75-kernel-module-loading-finit.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-kernel-module-loading-finit.rules-combo.yaml)
**Purpose:** Audits use of the `finit_module` syscall (kernel module loading).
**Potential Performance Impact:** Minimal, unless modules are loaded/unloaded frequently.

## [75-rhcos4-etc_audit_rules.d_75-kernel-module-loading-init.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-kernel-module-loading-init.rules-combo.yaml)
**Purpose:** Audits use of the `init_module` syscall (kernel module loading).
**Potential Performance Impact:** Minimal, unless modules are loaded/unloaded frequently.

## [75-rhcos4-etc_audit_rules.d_75-syscall-adjtimex.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-syscall-adjtimex.rules-combo.yaml)
**Purpose:** Audits the `adjtimex` syscall for time adjustments.
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-syscall-clock-settime.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-syscall-clock-settime.rules-combo.yaml)
**Purpose:** Audits the `clock_settime` syscall for time changes.
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-syscall-settimeofday.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-syscall-settimeofday.rules-combo.yaml)
**Purpose:** Audits the `settimeofday` syscall for time changes.
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-usr_bin_chcon_execution.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-usr_bin_chcon_execution.rules-combo.yaml)
**Purpose:** Audits execution of `/usr/bin/chcon` (SELinux context changes).
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-usr_sbin_restorecon_execution.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-usr_sbin_restorecon_execution.rules-combo.yaml)
**Purpose:** Audits execution of `/usr/sbin/restorecon` (SELinux context restore).
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-usr_sbin_semanage_execution.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-usr_sbin_semanage_execution.rules-combo.yaml)
**Purpose:** Audits execution of `/usr/sbin/semanage` (SELinux management).
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-usr_sbin_setfiles_execution.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-usr_sbin_setfiles_execution.rules-combo.yaml)
**Purpose:** Audits execution of `/usr/sbin/setfiles` (SELinux file labeling).
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-usr_sbin_setsebool_execution.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-usr_sbin_setsebool_execution.rules-combo.yaml)
**Purpose:** Audits execution of `/usr/sbin/setsebool` (SELinux boolean changes).
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_audit_rules.d_75-usr_sbin_seunshare_execution.rules-combo.yaml](./75-rhcos4-etc_audit_rules.d_75-usr_sbin_seunshare_execution.rules-combo.yaml)
**Purpose:** Audits execution of `/usr/sbin/seunshare` (SELinux user namespace separation).
**Potential Performance Impact:** Minimal.

## [75-rhcos4-etc_pam.d_password-auth-combo.yaml](./75-rhcos4-etc_pam.d_password-auth-combo.yaml)
**Purpose:** Sets up PAM configuration for password authentication, enforcing password quality and disabling empty passwords.
**Potential Performance Impact:** Negligible; may slightly increase authentication time due to password quality checks.

## [75-rhcos4-etc_pam.d_system-auth-combo.yaml](./75-rhcos4-etc_pam.d_system-auth-combo.yaml)
**Purpose:** Sets up PAM configuration for system authentication, enforcing password quality and disabling empty passwords.
**Potential Performance Impact:** Negligible; may slightly increase authentication time due to password quality checks.

---

## General Notes
- **Testing:** Always test MachineConfigs in a staging environment before applying to production, especially for performance-sensitive workloads.
- **Monitoring:** After applying, monitor CPU, memory, and disk I/O to ensure there are no unexpected impacts.

*Last updated: June 2, 2025*
