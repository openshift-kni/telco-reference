# Reference configuration
Note: This repository is a work in progress and might be subject to structural change.

## Structure
This directory contains three components of the reference configuration
 - The `source-crs` tree contains the CRs which make
   up the RAN reference configuration.
 - The `extra-manifests-builder` folder is used to create the extra-manifests in `source-crs/extra-manifest` directory.
 - The `kube-compare-reference` tree contains the RAN reference configuration CRs with templating required for kube-compare tool.
 - The `policygentemplates` tree has example yamls which serve as manifests to define how CRs from the
   source-crs tree are grouped into policies and apply certain use case specific patches to the policy wrapped CRs.
 - The `hub-side-templating` subdirectory holds ConfigMaps and Templates which provide values used in PGTs with hub side templating.
