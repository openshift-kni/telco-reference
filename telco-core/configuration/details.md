# YAML File Details

This document provides an overview of all YAML files in the repository, organized by directory, with a brief description of what each file does or configures. Use this as a reference for understanding the purpose of each manifest or configuration file.

---

## How to Use
- Click the file links to jump to the file in the repository.
- Each entry includes a short summary of the file's intent or function.

---

<!--
  To keep this file up to date, add new YAMLs as they are introduced and provide a short description for each.
-->

## [telco-core/configuration/](../telco-core/configuration/)
- [core-baseline.yaml](../telco-core/configuration/core-baseline.yaml): PolicyGenerator CR containing fixed required content for the core baseline configuration.
- [core-finish.yaml](../telco-core/configuration/core-finish.yaml): PolicyGenerator CR for finalization or post-processing steps in the core configuration.
- [core-overlay.yaml](../telco-core/configuration/core-overlay.yaml): PolicyGenerator CR for overlay content, including optional and patchable configuration.
- [core-upgrade.yaml](../telco-core/configuration/core-upgrade.yaml): PolicyGenerator CR for upgrade policies between releases.
- [kustomization.yaml](../telco-core/configuration/kustomization.yaml): Kustomize file for managing overlays and resource composition.
- [ns.yaml](../telco-core/configuration/ns.yaml): Namespace manifest for core configuration resources.

## [telco-core/configuration/template-values/](../telco-core/configuration/template-values/)
- [hw-types.yaml](../telco-core/configuration/template-values/hw-types.yaml): ConfigMap with hardware-dependent values for ACM policy templating.
- [regional.yaml](../telco-core/configuration/template-values/regional.yaml): ConfigMap with region/zone-dependent values for ACM policy templating.

## [telco-core/configuration/reference-crs/](../telco-core/configuration/reference-crs/)
- [required/](../telco-core/configuration/reference-crs/required/): Contains required baseline configuration CRs.
- [optional/](../telco-core/configuration/reference-crs/optional/): Contains optional configuration CRs.
- [custom-manifests/](../telco-core/configuration/reference-crs/custom-manifests/): Custom CRs for specific use cases.

## [telco-core/configuration/reference-crs-kube-compare/](../telco-core/configuration/reference-crs-kube-compare/)
- [compare_ignore](../telco-core/configuration/reference-crs-kube-compare/compare_ignore): List of files to ignore during cluster-compare checks.
- [comparison-overrides.yaml](../telco-core/configuration/reference-crs-kube-compare/comparison-overrides.yaml): Overrides for kube-compare tool.
- [metadata.yaml](../telco-core/configuration/reference-crs-kube-compare/metadata.yaml): Metadata for kube-compare reference.
- [ReferenceVersionCheck.yaml](../telco-core/configuration/reference-crs-kube-compare/ReferenceVersionCheck.yaml): Version check CR for reference comparison.
- [unordered_list.tmpl](../telco-core/configuration/reference-crs-kube-compare/unordered_list.tmpl): Template for unordered list rendering.
- [version_match.tmpl](../telco-core/configuration/reference-crs-kube-compare/version_match.tmpl): Template for version matching.
- [required/](../telco-core/configuration/reference-crs-kube-compare/required/): Required reference CR templates for kube-compare.
- [optional/](../telco-core/configuration/reference-crs-kube-compare/optional/): Optional reference CR templates for kube-compare.

---

<!-- Add additional sections for other directories and YAMLs as needed. -->
