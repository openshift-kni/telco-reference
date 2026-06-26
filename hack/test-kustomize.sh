#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Excluded: these use ZTP kustomize plugins only available in OpenShift ArgoCD with ACM/MCE.
EXCLUDED_DIRS=(
    "./telco-core/configuration"
    "./telco-ran/configuration/argocd/example/acmpolicygenerator"
    "./telco-ran/configuration/argocd/example/clusterinstance"
    "./telco-ran/configuration/argocd/example/image-based-upgrades"
    "./telco-ran/configuration/argocd/example/policygentemplates"
    "./telco-ran/configuration/argocd/example/siteconfig"
)

if ! command -v kustomize &> /dev/null; then
    echo -e "${RED}ERROR: kustomize is not installed${NC}"
    echo ""
    echo "Please install kustomize to run this check:"
    echo "  - macOS: brew install kustomize"
    echo "  - go install: go install sigs.k8s.io/kustomize/kustomize/v5@v5.8.1"
    echo "  - Manual: https://kubectl.docs.kubernetes.io/installation/kustomize/"
    echo ""
    exit 1
fi

echo "Checking all kustomization.yaml files can build successfully..."
echo ""

ERRORS=0
CHECKED=0
SKIPPED=0

is_excluded() {
    local dir="$1"
    for excluded in "${EXCLUDED_DIRS[@]}"; do
        if [ "$dir" = "$excluded" ]; then
            return 0
        fi
    done
    return 1
}

kustomize_files=()
while IFS= read -r file; do
    kustomize_files+=("$file")
done < <(find . -name 'kustomization.yaml' -not -path '*/venv/*' -not -path '*/.git/*' | sort)

if [ ${#kustomize_files[@]} -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No kustomization.yaml files found${NC}"
    exit 0
fi

for kustomize_file in "${kustomize_files[@]}"; do
    dir=$(dirname "$kustomize_file")
    echo -n "  $dir: "
    
    if is_excluded "$dir"; then
        echo -e "${BLUE}SKIPPED${NC} (requires external plugins)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    CHECKED=$((CHECKED + 1))
    output=$(kustomize build "$dir" 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        echo -e "${YELLOW}    Error details:${NC}"
        echo "$output" | sed 's/^/    /'
        echo ""
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "Summary: Checked $CHECKED kustomization.yaml files, skipped $SKIPPED (require external plugins)"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}All kustomization files validated successfully!${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS kustomization file(s) failed validation${NC}"
    exit 1
fi

