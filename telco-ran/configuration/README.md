# Reference configuration
Note: This repository is a work in progress and might be subject to structural change.

## Structure
This directory contains three components of the reference configuration
 - The `source-crs` tree contains the CRs which form the foundation of
   the RAN reference configuration.
 - The `extra-manifests-builder` folder is used to create the extra-manifests in `source-crs/extra-manifest` directory.
 - The `kube-compare-reference` tree contains the RAN reference configuration CRs with templating required for kube-compare tool.
 - The `policygentemplates` tree has the reference manifests which define how CRs from the
   source-crs tree are patched with use-case specific patches and grouped into policies in order to generate policies which apply the reference configuration to one or more clusters.
 - The `hub-side-templating` subdirectory holds ConfigMaps and Templates which provide values used in PGTs with hub side templating.
