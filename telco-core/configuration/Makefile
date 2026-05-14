.PHONY: check
check: compare_crs missing_crs check_core_install_extra_manifest_sync

.PHONY: check_core_install_extra_manifest_sync
check_core_install_extra_manifest_sync:
	bash ../../hack/check-core-install-extra-manifest-sync.sh

.PHONY: compare_crs
compare_crs:
	@CLUSTER_COMPARE=$$(command -v kubectl-cluster_compare); \
	if [[ -z $${CLUSTER_COMPARE} ]]; then \
		echo "kubectl-cluster_compare tool isn't installed; please download it from https://github.com/openshift/kube-compare"; \
		exit 1; \
	fi; \
	$${CLUSTER_COMPARE} -r ./reference-crs-kube-compare/metadata.yaml -f ./reference-crs,./hack/cluster-default-crs -R -p ./reference-crs-kube-compare/comparison-overrides.yaml


.PHONY: missing_crs
missing_crs:
	./compare.sh reference-crs reference-crs-kube-compare reference-crs-kube-compare/compare_ignore

