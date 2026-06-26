# Openshift folder
This extra-manifest folder contains CRs which will be applied to the cluster during installation. These CRs may need to be adjusted based on your specific environment as noted in comments in the CR. The CRs may be optional as noted in a comment at the top of the file.
Using the openshift folder imposes a restriction: its contents cannot override default cluster manifests.