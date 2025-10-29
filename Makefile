
IMAGE_NAME ?= telco-reference

CONTAINER_TOOL ?= podman

# Check that all required dependencies are installed
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies for ci-validate..."
	@echo ""
	@MISSING=0; \
	echo -n "Checking yamllint... "; \
	if command -v yamllint >/dev/null 2>&1; then \
		echo "✓ Found: $$(yamllint --version)"; \
	else \
		echo "✗ Missing (install: pip install yamllint or brew install yamllint)"; \
		MISSING=$$((MISSING+1)); \
	fi; \
	echo -n "Checking kubectl-cluster_compare... "; \
	if command -v kubectl-cluster_compare >/dev/null 2>&1; then \
		echo "✓ Found: $$(kubectl-cluster_compare --version 2>&1 | head -1)"; \
	else \
		echo "✗ Missing (install from: https://github.com/openshift/kube-compare/releases)"; \
		MISSING=$$((MISSING+1)); \
	fi; \
	echo -n "Checking helm-convert... "; \
	if command -v helm-convert >/dev/null 2>&1; then \
		echo "✓ Found"; \
	else \
		echo "✗ Missing (install: go install github.com/openshift/kube-compare/addon-tools/helm-convert@latest)"; \
		MISSING=$$((MISSING+1)); \
	fi; \
	echo -n "Checking mcmaker... "; \
	if command -v mcmaker >/dev/null 2>&1; then \
		echo "✓ Found"; \
	else \
		echo "✗ Missing (install: go install github.com/lack/mcmaker@latest)"; \
		MISSING=$$((MISSING+1)); \
	fi; \
	echo -n "Checking go... "; \
	if command -v go >/dev/null 2>&1; then \
		echo "✓ Found: $$(go version)"; \
	else \
		echo "✗ Missing (install from: https://go.dev/dl/)"; \
		MISSING=$$((MISSING+1)); \
	fi; \
	echo ""; \
	if [ $$MISSING -eq 0 ]; then \
		echo "✅ All dependencies are installed!"; \
		echo "You can now run: make ci-validate"; \
		exit 0; \
	else \
		echo "❌ Missing $$MISSING dependencies. Please install them to run ci-validate."; \
		exit 1; \
	fi

# Basic lint checking
lintCheck:
	# The configuration is done piece-wise in order to skip the
	# kube-compare reference tree. Those yamls are augmented with
	# golang templating and are not expected to be legal yaml.
	yamllint -c .yamllint.yaml telco-core/configuration/*yaml
	yamllint -c .yamllint.yaml telco-core/configuration/reference-crs
	yamllint -c .yamllint.yaml telco-core/configuration/template-values
	yamllint -c .yamllint.yaml telco-core/install/
	yamllint -c .yamllint.yaml telco-hub/configuration/*yaml
	yamllint -c .yamllint.yaml telco-hub/configuration/reference-crs
	yamllint -c .yamllint.yaml telco-hub/configuration/example-overlays-config
	yamllint -c .yamllint.yaml telco-hub/install/

# markdownlint rules, following: https://github.com/openshift/enhancements/blob/master/Makefile
.PHONY: markdownlint-image
markdownlint-image:  ## Build local container markdownlint-image
	$(CONTAINER_TOOL) image build -f ./hack/Dockerfile.markdownlint --tag $(IMAGE_NAME)-markdownlint:latest ./hack

.PHONY: markdownlint-image-clean
markdownlint-image-clean:  ## Remove locally cached markdownlint-image
	$(CONTAINER_TOOL) image rm $(IMAGE_NAME)-markdownlint:latest

markdownlint: markdownlint-image  ## run the markdown linter
	$(CONTAINER_TOOL) run \
		--rm=true \
		--env RUN_LOCAL=true \
		--env VALIDATE_MARKDOWN=true \
		--env PULL_BASE_SHA=$(PULL_BASE_SHA) \
		-v $$(pwd):/workdir:Z \
		$(IMAGE_NAME)-markdownlint:latest

.PHONY: ocp-doc-check
ocp-doc-check:  ## Download and run ocp-doc-checker against markdown files
	@echo "Detecting platform..."
	@OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	ARCH=$$(uname -m); \
	if [ "$$OS" = "mingw64_nt" ] || [ "$$OS" = "msys_nt" ]; then \
		echo "Windows is not supported, skipping ocp-doc-check"; \
		exit 0; \
	fi; \
	if [ "$$ARCH" = "x86_64" ]; then \
		ARCH="amd64"; \
	elif [ "$$ARCH" = "aarch64" ]; then \
		ARCH="arm64"; \
	fi; \
	BINARY_NAME="ocp-doc-checker-$$OS-$$ARCH"; \
	DOWNLOAD_URL="https://github.com/sebrandon1/ocp-doc-checker/releases/latest/download/$$BINARY_NAME"; \
	echo "Downloading $$BINARY_NAME from $$DOWNLOAD_URL..."; \
	if ! curl -L -f -o ./$$BINARY_NAME $$DOWNLOAD_URL; then \
		echo "Failed to download ocp-doc-checker binary"; \
		exit 1; \
	fi; \
	chmod +x ./$$BINARY_NAME; \
	echo "Running ocp-doc-checker against repository..."; \
	./$$BINARY_NAME -dir . || true; \
	rm -f ./$$BINARY_NAME; \
	echo "ocp-doc-check completed"

test-kustomize:  ## Validate all kustomization.yaml files can build
	./hack/test-kustomize.sh

ci-validate: lintCheck check-reference-core check-reference-ran check-reference-hub

.PHONY: check-reference-core
check-reference-core:
	$(MAKE) -C ./telco-core/configuration check

.PHONY: check-reference-ran
check-reference-ran:
	$(MAKE) -C ./telco-ran/configuration check

.PHONY: check-reference-hub
check-reference-hub:
	$(MAKE) -C ./telco-hub/configuration/reference-crs-kube-compare check
