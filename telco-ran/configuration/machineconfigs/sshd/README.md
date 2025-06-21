# MachineConfigs in `machineconfigs/sshd`

This directory contains MachineConfig YAMLs that configure SSH daemon (sshd) settings for RHCOS nodes. Each file is listed below with a summary and performance note.

---

## [75-rhcos4-etc_ssh_sshd_config-combo.yaml](./75-rhcos4-etc_ssh_sshd_config-combo.yaml)
**Purpose:** Configures `/etc/ssh/sshd_config` with a combined set of security-focused SSH daemon settings, including:
- Disabling root login (`PermitRootLogin no`)
- Enforcing strict modes (`StrictModes yes`)
- Disabling empty passwords (`PermitEmptyPasswords no`)
- Disabling password authentication (`PasswordAuthentication no`)
- Disabling GSSAPI and Kerberos authentication (`GSSAPIAuthentication no`, `KerberosAuthentication no`)
- Disabling user environment variables (`PermitUserEnvironment no`)
- Disabling rhosts and user known hosts (`IgnoreRhosts yes`, `IgnoreUserKnownHosts yes`)
- Setting log level (`LogLevel INFO`)
- Enabling public key authentication (`PubkeyAuthentication yes`)
- Setting client keepalive (`ClientAliveInterval 300`, `ClientAliveCountMax 0`)
- Disabling compression (`Compression no`)
- Setting banner (`Banner /etc/issue`)
- Enabling PAM (`UsePAM yes`)
- Enforcing privilege separation (`UsePrivilegeSeparation sandbox`)
- Other hardening and logging options

**Potential Performance Impact:**
- Most settings have negligible performance impact.
- Disabling compression (`Compression no`) may increase network bandwidth usage for large file transfers, but reduces CPU usage on both client and server.
- Disabling GSSAPI and Kerberos authentication can slightly reduce authentication overhead.
- Enabling strict modes and disabling root login improve security with no measurable performance cost.
- Frequent keepalive (`ClientAliveInterval 300`) may increase minimal network traffic but helps detect dead sessions.

---

## General Notes
- **Testing:** Always test MachineConfigs in a staging environment before applying to production, especially for security-sensitive workloads.
- **Monitoring:** After applying, verify SSH access and monitor authentication logs for unexpected issues.

*Last updated: June 2, 2025*
