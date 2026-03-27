# Installation artifacts
Note: This method is deprecated in favor of the ClusterInstance CR from the [siteconfig operator](https://github.com/stolostron/siteconfig).

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

## Workarounds

### Cluster App shows diff in BMH ignition config override annotation
Issue link: [OCPBUGS-63080](https://issues.redhat.com/browse/OCPBUGS-63080)

When using a node level ignition config override in your siteconfig CR, the annotation is propagated to BMH and tracked by Argo. After installation, assisted service injects a certificate for MCS that is used by day-2 worker nodes. This may cause Argo to flag a diff on the clusters-app. Use one of the patches below as a workaround for this behavior.

If no ignoreDifferences config is present for clusters-app, 
```
oc patch applications.argoproj.io "clusters-app-name" -n openshift-gitops --type merge -p '{"spec":{"ignoreDifferences":[{"group":"metal3.io","kind":"BareMetalHost","jsonPointers":["/metadata/annotations/bmac.agent-install.openshift.io~1ignition-config-overrides"]}]}}'
```
To append to an existing ignoreDifferences config,
```
oc patch applications.argoproj.io "clusters-app-name" -n openshift-gitops --type json -p '[{"op":"add","path":"/spec/ignoreDifferences/-","value":{"group":"metal3.io","kind":"BareMetalHost","jsonPointers":["/metadata/annotations/bmac.agent-install.openshift.io~1ignition-config-overrides"]}}]'
```