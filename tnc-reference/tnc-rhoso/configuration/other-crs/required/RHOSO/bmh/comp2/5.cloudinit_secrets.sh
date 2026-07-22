echo "Creating user data secret. First delete if secret already exists"
oc -n openstack delete secret nodeset-dpdk-cloudinit-userdata-comp2
oc -n openstack create secret generic nodeset-dpdk-cloudinit-userdata-comp2 --from-file=userData=dpdk-userdata.yaml

echo "Creating network data secret. First delete if secret already exists"
oc -n openstack delete secret nodeset-dpdk-cloudinit-networkdata-comp2
oc -n openstack create secret generic nodeset-dpdk-cloudinit-networkdata-comp2 --from-file=networkData=dpdk-networkdata.yaml
