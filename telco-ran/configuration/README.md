# Reference configuration

## Structure
This directory contains three components of the reference configuration
 - The `source-crs` tree contains the CRs which form the foundation of
   the RAN reference configuration.
 - The `extra-manifests-builder` folder is used to create the extra-manifests in `source-crs/extra-manifest` directory.
 - The `kube-compare-reference` tree contains the RAN reference configuration CRs with templating required for kube-compare tool.
 - The `argocd` folder contains documentation and templates in `examples`
 - The `examples/policygentemplates` tree has the reference manifests which define how CRs from the
   source-crs tree are patched with use-case specific patches and grouped into policies in order to generate policies which apply the reference configuration to one or more clusters.
 - The `examples/acmpolicygenerator` tree has the reference manifests that are the recommended alternative to PGT CRs for generating ACM policies.
 - Both policygentemplates and acmpolicygenerator directories contain untemplated examples for all cluster configuration. Under each of the two directories there is also a hub-side-templating directory which contains examples for how to use hub templates for declaring the policies.
 - The `examples/image-based-upgrades` contain examples pertaining to image based upgrades.