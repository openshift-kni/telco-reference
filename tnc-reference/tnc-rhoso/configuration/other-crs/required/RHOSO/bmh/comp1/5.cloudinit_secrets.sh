echo "Creating user data secret. First delete if secret already exists"
oc -n openstack delete secret nodeset-sriov-cloudinit-userdata-comp1
oc -n openstack create secret generic nodeset-sriov-cloudinit-userdata-comp1 --from-file=userData=sriov-userdata.yaml

echo "Creating network data secret. First delete if secret already exists"
oc -n openstack delete secret nodeset-sriov-cloudinit-networkdata-comp1
oc -n openstack create secret generic nodeset-sriov-cloudinit-networkdata-comp1 --from-file=networkData=sriov-networkdata.yaml
