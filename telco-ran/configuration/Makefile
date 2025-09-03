
.PHONY: check checkExtraManifests checkSourceCRsAnnotation checkZtpPaths check-reference checkPolicyPaths

check: checkExtraManifests checkSourceCRsAnnotation checkZtpPaths check-reference checkPolicyPaths

checkExtraManifests:
	$(MAKE) -C ./extra-manifests-builder check

checkSourceCRsAnnotation:
	@failures=0; \
	 echo 'Checking for ztp-deploy-wave in source-crs/**/*.yaml:';\
	for sourcefile in $$(find ./source-crs/ -name '*.yaml'); do \
		echo -n "  $${sourcefile}: "; \
		case "$${sourcefile}" in \
			*/extra-manifest/* | \
			*/optional-extra-manifest/* | \
			*/machine-config/* | \
			*/validatorCRs/* | \
			*/MachineConfig* | \
			*/generic/* | \
			*/deprecated/workload/* | \
			*/ibu/* ) \
				echo "skip"; \
				continue \
				;; \
		esac; \
		if ! grep -qE "ran.openshift.io/ztp-deploy-wave" "$${sourcefile}"; then \
			echo "MISSING"; \
			(( failures += 1 )); \
		else \
			echo "OK"; \
		fi; \
	done; \
	exit $$failures

# ZTP_HOME is a temporary hard-coded path to site-generate container's ztp folder
# Should remain consistent across upstream, midstream and CI script
ZTP_HOME=/home/ztp/
checkFilePath:
	@failures=0; \
	echo 'Checking for filename path length in $(CUSTOM_RESOURCE):'; \
	for cr in $(shell find $(CUSTOM_RESOURCE) -type f); do \
		path="${ZTP_HOME}$$cr"; \
		echo -n "  $$path: "; \
		path_length=$$(echo -n $$path | wc -c); \
		if [ $$path_length -gt 255 ]; then \
			echo "TOO LONG (length: $$path_length)"; \
			(( failures += 1 )); \
		else \
			echo "OK (length: $$path_length)"; \
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

checkPolicyPaths:
	./hack/checkpolicypaths.sh ./argocd/
