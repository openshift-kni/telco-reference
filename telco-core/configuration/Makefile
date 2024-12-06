CLUSTER_COMPARE_DOWNLOAD_URL := $(shell curl -s https://api.github.com/repos/openshift/kube-compare/releases/latest | jq -r '.assets[] | select(.name? | match("kube-compare_linux_amd64")) | .browser_download_url')
CLUSTER_COMPARE_DIR=/tmp
CLUSTER_COMPARE_BIN=$(CLUSTER_COMPARE_DIR)/kubectl-cluster_compare
CLUSTER_COMPARE :=  $(if $(shell command -v kubectl-cluster_compare 2>/dev/null), $(shell command -v kubectl-cluster_compare), $(CLUSTER_COMPARE_BIN))

.PHONY: check
check: compare_crs missing_crs


.PHONY: compare_crs
compare_crs: $(CLUSTER_COMPARE)
	$(CLUSTER_COMPARE) -r ./reference-crs-kube-compare/metadata.yaml -f ./reference-crs -R || true

$(CLUSTER_COMPARE_BIN):
	@echo "kube-compare tool is not installed, download it to $@" \
	&& cd $(CLUSTER_COMPARE_DIR) && curl -sL $(CLUSTER_COMPARE_DOWNLOAD_URL) -o $@.tgz \
	&& tar zxvf $@.tgz kubectl-cluster_compare && rm -f $@.tgz


.PHONY: missing_crs
missing_crs:
	./compare.sh reference-crs reference-crs-kube-compare compare_ignore || true

.PHONY: clean
clean:
	rm -rf $(CLUSTER_COMPARE_BIN)

