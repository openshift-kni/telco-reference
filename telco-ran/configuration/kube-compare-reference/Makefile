.PHONY: check
check: metadata_lint compare

kubectl-cluster_compare:
	@command -v kubectl-cluster_compare > /dev/null 2>&1 || { \
		echo "kubectl-cluster_compare tool isn't installed; please download it from https://github.com/openshift/kube-compare"; \
	}

.PHONY: metadata_lint
metadata_lint: kubectl-cluster_compare
	@echo "Running kube-compare to ensure metadata.yaml is sane"
	@COMPARE_OUTPUT=$$(./kubectl-cluster_compare -r ./metadata.yaml -f /dev/null 2>&1); \
	if grep -q 'an error occurred while parsing template' <<<"$${COMPARE_OUTPUT}"; then \
		echo "Template parsing error"; \
		echo "$${COMPARE_OUTPUT}"; \
		exit 1; \
	fi; \
	echo "Okay"; \
	exit 0

.PHONY: compare
compare:
	@./hack/compare.sh ../source-crs ./metadata.yaml ./hack/default_value.yaml ./hack/compare_ignore

.PHONY: sync
sync:
	@./hack/compare.sh --sync ../source-crs ./metadata.yaml ./hack/default_value.yaml ./hack/compare_ignore
