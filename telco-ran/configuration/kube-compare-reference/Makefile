.PHONY: check
check: metadata_lint compare

kubectl-cluster_compare:
	@command -v kubectl-cluster_compare > /dev/null 2>&1 || { \
		echo "kubectl-cluster_compare tool isn't installed; please download it from https://github.com/openshift/kube-compare"; \
	}

helm-convert:
	@command -v helm-convert > /dev/null 2>&1 || { \
		echo "helm-convert isn't installed; please download and install it"; \
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

.PHONY: clean
clean:
	rm -rf kubectl-cluster_compare Chartv1 renderedv1 helm


.PHONY: convert
convert: helm-convert helm
	@echo "Converting reference files to Helm Charts."
	@rm -rf Chartv1 renderedv1
	@helm-convert -r ./metadata.yaml -n Chartv1 -v default_value.yaml
	@echo "Rendering Helm Charts to CR files."
	@helm template renderedv1 ./Chartv1 --output-dir renderedv1

helm:
	@command -v helm > /dev/null 2>&1 || { \
		echo "helm isn't installed; please download and install it"; \
	}

.PHONY: compare
compare: convert
	@./compare.sh "../source-crs" renderedv1

.PHONY: sync
sync: convert
	@./compare.sh --sync "../source-crs" renderedv1
