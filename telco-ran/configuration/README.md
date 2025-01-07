# Reference configuration
Note: This repository is a work in progress and might be subject to structural change.

## Structure
This directory contains three components of the reference configuration
 - The `source-crs` tree contains the baseline configuration CRs which make
   up the RAN reference configuration.
 - The `kube-compare-reference` tree contains the RAN reference configuration with templating required for kube-compare tool.
 - The `policygentemplates` tree root yamls serve as manifests which define how CRs from the
   source-crs tree are grouped into policies and apply certain use case
   specific patches to the policy wrapped CRs.
 - The `hub-side-templating` subdirectory holds ConfigMaps and Templates which provide values used in PGTs with hub side templating.
