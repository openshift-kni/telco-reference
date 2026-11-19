# Telco Core Reference Configuration (kube-compare)

This directory contains reference configurations for validating OpenShift Telco Core deployments using [kube-compare](https://github.com/openshift/kube-compare).

## Overview

The reference configuration consists of YAML templates with fixed and optional content. Optional content is represented as Go templates that are injected with cluster CR parameters during comparison.

**Key file:** `metadata.yaml` - Defines all resource templates, components, and validation rules.

## Template Functions

Custom Go template functions are defined in separate `.tmpl` files and registered in `templateFunctionFiles`:

### validateBase64List

Validates newline-separated lists against an allowed set of values. Supports both base64-encoded and plain text data URIs.

**Usage:**
```yaml
source: {{ template "validateBase64List" (list $sourceField $allowedItems) }}
```

**Formats:**
- Base64: `data:text/plain;charset=utf-8;base64,<base64-content>`
- Plain text: `data:,item1%0Aitem2%0Aitem3` (URL-encoded newlines)

**Behavior:**
- Returns original source if all items are in the allowed list
- Returns error message `data:,Items not in allowed list <items>` if disallowed items found
- Handles whitespace trimming, blank lines, empty content

**Example:** See `optional/other/worker-load-kernel-modules.yaml` for kernel module validation.

## Updating References

**Key considerations:**

1. **Test with kube-compare:** Always validate template changes with actual cluster CRs:
   ```bash
   kube-compare -r metadata.yaml -f /path/to/cluster/crs
   ```

2. **Template syntax:** All templates must produce valid YAML after injection, even with empty input.

3. **Function registration:** Custom template functions must be listed in `templateFunctionFiles` in `metadata.yaml`.

4. **Data URI encoding:** Plain text data URIs must URL-encode special characters (`%0A` for newlines, `%20` for spaces, etc.).

5. **Backward compatibility:** Changes to template functions must maintain compatibility with existing CRs.

## Related Documentation

- [Telco Core Reference Design](https://docs.openshift.com/container-platform/4.20/scalability_and_performance/telco_ref_design_specs/core/telco-core-ref-design-components.html)
- [kube-compare Documentation](https://github.com/openshift/kube-compare)
