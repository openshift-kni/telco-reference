.PHONY: check
check: compare_crs missing_crs


.PHONY: compare_crs
compare_crs:
	@CLUSTER_COMPARE=$$(command -v kubectl-cluster_compare); \
	if [[ -z $${CLUSTER_COMPARE} ]]; then \
		echo "kubectl-cluster_compare tool isn't installed; please download it from https://github.com/openshift/kube-compare"; \
		exit 1; \
	fi; \
	$${CLUSTER_COMPARE} -r ./reference-crs-kube-compare/metadata.yaml -f ./reference-crs -R -p ./reference-crs-kube-compare/comparison-overrides.yaml


.PHONY: missing_crs
missing_crs:
	./compare.sh reference-crs reference-crs-kube-compare reference-crs-kube-compare/compare_ignore