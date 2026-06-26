#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! command -v shellcheck &> /dev/null; then
    echo -e "${RED}ERROR: shellcheck is not installed${NC}"
    echo ""
    echo "Please install shellcheck to run this check:"
    echo "  - macOS: brew install shellcheck"
    echo "  - Fedora/RHEL: dnf install ShellCheck"
    echo "  - Ubuntu/Debian: apt-get install shellcheck"
    echo "  - Manual: https://github.com/koalaman/shellcheck#installing"
    echo ""
    exit 1
fi

echo "Running ShellCheck on all shell scripts..."
echo ""

ERRORS=0
CHECKED=0

shell_files=()
while IFS= read -r file; do
    shell_files+=("$file")
done < <(find . -name '*.sh' -not -path './.git/*' -not -path './venv/*' -not -path '*/.venv/*' -not -path './sdk-go/*' | sort)

if [ ${#shell_files[@]} -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No shell scripts found${NC}"
    exit 0
fi

for script in "${shell_files[@]}"; do
    echo -n "  $script: "
    CHECKED=$((CHECKED + 1))
    output=$(shellcheck --severity=error "$script" 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        echo "$output" | sed 's/^/    /'
        echo ""
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "Summary: Checked $CHECKED shell scripts"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}All shell scripts passed ShellCheck!${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS script(s) failed ShellCheck${NC}"
    exit 1
fi
