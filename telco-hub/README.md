# telco-hub

## Description

This directory contains reference configuration CRs and manifests related to the Telco Hub use models. The content is branched for each y-stream release of OpenShift.

Click [here](./yaml_details.md) to view the details of each YAML file in this subdirectory.

## Contributing

If you would like to contribute content to this reference configuration please open a pull request and include a link to the associated feature development.

## Support

If you have questions or comments on this reference configuration please reach out to one of the owners of this project.

### Mirror registry

The instructions that follow consider a partially-disconnected environment. In this kind of environment there is a host that has
Internet connectivity but the OCP nodes of the Hub cluster are disconnected. This scenario has the advantage that it allows to create and
populate the mirror registry directly using the public repositories while proceeding with the Hub cluster installation as if it was fully-disconnected.
For a fully disconnected environment a few additional step are required (see [Mirroring an image set in a fully disconnected environment](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/disconnected_environments/index#mirroring-image-set-full)).

[Mirror registry setup](install/mirror-registry/README.md)

## Automated installation
This is the recommended approach to install the Hub cluster. The automation uses the GitOps operator to deploy and configure all the required components. See [Automated installation](configuration/README.md) for more information.

## Manual configuration of Hub components

The following instructions cover the installation and configuration of the day-2 operators required to turn the basic OpenShift cluster into a Hub cluster.
They should be installed in the order presented here to ensure that the resource dependencies are properly resolved.

**IMPORTANT:** Do not forget to modify the reference CRs to match your environment and needs.

### Required operators

#### [GITOPS](configuration/reference-crs/required/gitops/readme.md)

#### [LSO](configuration/reference-crs/optional/lso/README.md)

#### [ODF](configuration/reference-crs/optional/odf-internal/README.md)

#### [ACM](configuration/reference-crs/required/acm/readme.md)


### Optional configuration

#### Backup and recovery

[Backup and recovery process](configuration/reference-crs/optional/backup-recovery/README.md)
## Authors and acknowledgment

Many thanks to those who have contributed to this reference configuration.
