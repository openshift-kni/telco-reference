
# clean ceph

```
oc debug node/master-0.hub-1.el8k.se-lab.eng.rdu2.dc.redhat.com -- sh -c 'chroot /host; DISK="/dev/nvme1n1";dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=0;dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((1 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((10 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((100 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((1000 * 1024**2)); blkdiscard $DISK; partprobe $DISK '

oc debug node/master-1.hub-1.el8k.se-lab.eng.rdu2.dc.redhat.com -- sh -c 'chroot /host; DISK="/dev/nvme1n1";dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=0;dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((1 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((10 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((100 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((1000 * 1024**2)); blkdiscard $DISK; partprobe $DISK '


oc debug node/master-2.hub-1.el8k.se-lab.eng.rdu2.dc.redhat.com -- sh -c 'chroot /host; DISK="/dev/nvme1n1";dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=0;dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((1 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((10 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((100 * 1024**2)); dd if=/dev/zero of="$DISK" bs=1K count=200 oflag=direct,dsync seek=$((1000 * 1024**2)); blkdiscard $DISK; partprobe $DISK '

```
# patch all the nodes to use odf

```
oc label node master-0.hub-1.el8k.se-lab.eng.rdu2.dc.redhat.com cluster.ocs.openshift.io/openshift-storage=
oc label node master-1.hub-1.el8k.se-lab.eng.rdu2.dc.redhat.com cluster.ocs.openshift.io/openshift-storage=
oc label node master-2.hub-1.el8k.se-lab.eng.rdu2.dc.redhat.com cluster.ocs.openshift.io/openshift-storage=
```

# make the env disconnected:
delete the default catalogsources

```
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

then create the disconnected CRs

```
$ cat << EOF | oc apply -f -
---
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
  name: idms-operator-0
spec:
  imageDigestMirrors:
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/rhceph
    source: registry.redhat.io/rhceph
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/rhel9
    source: registry.redhat.io/rhel9
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/oadp
    source: registry.redhat.io/oadp
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/openshift-gitops-1
    source: registry.redhat.io/openshift-gitops-1
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/openshift4
    source: registry.redhat.io/openshift4
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/rhel8
    source: registry.redhat.io/rhel8
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/rh-sso-7
    source: registry.redhat.io/rh-sso-7
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/odf4
    source: registry.redhat.io/odf4
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/multicluster-engine
    source: registry.redhat.io/multicluster-engine
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/rhacm2
    source: registry.redhat.io/rhacm2
status: {}
---
apiVersion: config.openshift.io/v1
kind: ImageTagMirrorSet
metadata:
  name: itms-generic-0
spec:
  imageTagMirrors:
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/openshift4
    source: registry.redhat.io/openshift4
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/ubi8
    source: registry.redhat.io/ubi8
  - mirrors:
    - registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/rhel8
    source: registry.redhat.io/rhel8
status: {}
EOF

```

add the CA for the registry

```
oc create -f registry-cas.yaml
```
the manifest

```
apiVersion: v1
data:
  registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com..8443: |
    -----BEGIN CERTIFICATE-----
    MIIGBzCCA++gAwIBAgIUHT7vQrmFpjof6PPgCieq/OzNWiUwDQYJKoZIhvcNAQEL
    qg/qvGTlRsro4nVP/baySiIG8nTdKx0HBTNLF8uKDmF+SbuzooLv5rtuRldHSSr9
    YGpVvM1Lav05C4Y=
    -----END CERTIFICATE-----
kind: ConfigMap
metadata:
  name: registry-cas
  namespace: openshift-config

```
get the certificate with:

```
openssl s_client -showcerts -verify 5 -connect registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443 < /dev/null
```

make the patch to use that CA

```
 oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge
```

and the pull-secret with the access to this disconnected registry

```
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=/home/jgato/.config/containers/auth.json

```

and create the registry

```
cat << EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operators-disconnected
  namespace: openshift-marketplace
spec:
  image: registry.infra.el8k.se-lab.eng.rdu2.dc.redhat.com:8443/openshift-marketplace/redhat-operators-disconnected:v4.19
  sourceType: grpc
EOF

```

you can also find these resources (CatalogSource and the Images-) on
`oc-mirror-workspace/working-dir/cluster-resources/` after generating the mirror.






error when patching "/dev/shm/4058753072": multiclusterengines.multicluster.openshift.io "multiclusterengine" is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot patch resource "multiclusterengines" in API group "multicluster.openshift.io" at the cluster scope


