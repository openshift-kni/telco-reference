# Installation artifacts
Note: This repository is a work in progress and might be subject to structural change.

## Structure
This directory contains a folder `siteconfig` with example CRs for installation of a Telco RAN cluster
using [Multi Cluster
Engine (MCE)](https://github.com/stolostron/deploy/tree/master/multiclusterengine). The
CRs contained here are examples and must be tuned/configured to your particular
hardware and environment. However these represent the best-practices and the
general pattern shown here is recommended.

## SiteConfig CRs
The `siteconfig` folder contains SiteConfig CRs which define the
topology and specific attributes of a cluster. This CR may be rendered into MCE
installation CRs using the [SiteGen
utility](https://github.com/openshift-kni/cnf-features-deploy/tree/master/ztp/siteconfig-generator). The
SiteConfig defines:
 - cluster identity -- name, FQDN, API/ingress VIPs, etc
 - cluster topology -- number of control plane and nodes, node labels for
   allocation to Machine Config Pools, etc
 - cluster networking -- per-node network interface details, cluster networking
   attributes, etc
 - node attributes -- ignition config may be provided to partition disks per
   node