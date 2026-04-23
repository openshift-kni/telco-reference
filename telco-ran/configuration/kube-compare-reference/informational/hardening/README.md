# Hardening Reference Configurations

Reference MachineConfig CRs for HIGH severity compliance remediations based on
OpenShift Compliance Operator findings (E8/CIS benchmarks).

These configurations are **informational** — they are provided as guidance for
security hardening. When validated with `kube-compare`, differences are reported
as warnings but do not cause validation failure.

## Configurations

| File | Description | Compliance Check |
|------|-------------|-----------------|
| `75-crypto-policy-high-master.yaml` | Sets system-wide crypto policy to `DEFAULT:NO-SHA1` on control plane nodes | `rhcos4-e8-master-configure-crypto-policy` |
| `75-crypto-policy-high-worker.yaml` | Sets system-wide crypto policy to `DEFAULT:NO-SHA1` on worker nodes | `rhcos4-e8-worker-configure-crypto-policy` |
| `75-pam-auth-high-master.yaml` | Removes `nullok` from PAM auth to prevent empty password authentication on control plane nodes | `rhcos4-e8-master-no-empty-passwords` |
| `75-pam-auth-high-worker.yaml` | Removes `nullok` from PAM auth to prevent empty password authentication on worker nodes | `rhcos4-e8-worker-no-empty-passwords` |
| `75-sshd-permit-empty-passwords-master.yaml` | Sets `PermitEmptyPasswords no` in SSHD configuration on control plane nodes | `rhcos4-e8-master-sshd-disable-empty-passwords` |
| `75-sshd-permit-empty-passwords-worker.yaml` | Sets `PermitEmptyPasswords no` in SSHD configuration on worker nodes | `rhcos4-e8-worker-sshd-disable-empty-passwords` |
