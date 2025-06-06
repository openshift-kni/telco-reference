
.PHONY: check checkExtraManifests checkSourceCRsAnnotation checkZtpPaths check-reference

check: checkExtraManifests checkSourceCRsAnnotation checkZtpPaths check-reference

checkExtraManifests:
	$(MAKE) -C ./extra-manifests-builder check

checkSourceCRsAnnotation:
	for sourcefile in ./source-crs/*.yaml;do \
		if [[ "$${sourcefile}" != *"MachineConfig"* && "$${sourcefile}" != *"/ConfigMapGeneric.yaml" ]];then \
			if ! grep -qE "ran.openshift.io/ztp-deploy-wave" "$${sourcefile}";then \
				echo "Error: missing annotation 'ran.openshift.io/ztp-deploy-wave' in $${sourcefile}"; \
				exit 1; \
			fi; \
		fi; \
	done; \

# ZTP_HOME is a temporary hard-coded path to site-generate container's ztp folder
# Should remain consistent across upstream, midstream and CI script
ZTP_HOME=/home/ztp/
checkFilePath:
	@failures=0; \
	for cr in $(shell find $(CUSTOM_RESOURCE) -type f); do \
	  path_length=$$(echo -n ${ZTP_HOME}$$cr | wc -c); \
	  if [ $$path_length -gt 255 ]; then \
	    echo "File path too long: ${ZTP_HOME}$$cr (length: $$path_length)"; \
		(( failures += 1 )); \
	  else \
	    echo "File path OK: ${ZTP_HOME}$$cr (length: $$path_length)"; \
	  fi; \
	done; \
	exit $$failures

# checkZtpPaths ci job ensures that filenames in this repo are not greater than 255.
# This limitation comes from the ISO9660 standard with Rock Ridge extensions.
# Related Issue: https://issues.redhat.com/browse/OCPBUGS-48244
checkZtpPaths:
	$(MAKE) CUSTOM_RESOURCE=source-crs checkFilePath
	$(MAKE) CUSTOM_RESOURCE=argocd checkFilePath
	$(MAKE) CUSTOM_RESOURCE=kube-compare-reference checkFilePath

check-reference:
	$(MAKE) -C ./kube-compare-reference check
