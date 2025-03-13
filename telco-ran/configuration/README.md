# Reference configuration

## Structure
This directory contains three components of the reference configuration:
 - source-crs contains the CRs which form the foundation of
   the RAN reference configuration.
 - extra-manifests-builder is used to create the extra-manifests in `source-crs/extra-manifest` directory.
 - kube-compare-reference contains the RAN reference configuration CRs with templating required for the kube-compare tool.
 - argocd contains documentation and templates in `examples`.
 - examples/policygentemplates has the reference manifests which define how CRs from the
   source-crs tree are patched with use-case specific patches and grouped into ordered policies which apply the reference configuration to one or more clusters.
 - examples/acmpolicygenerator has the reference manifests that are the recommended alternative to PGT CRs for generating ACM policies.
 - Both policygentemplates and acmpolicygenerator directories contain untemplated examples for all cluster configuration. Under each of the two directories there is also a hub-side-templating directory which contains examples for how to use hub templates for declaring the policies.
 - examples/image-based-upgrades contain examples pertaining to image based upgrades.