#!/bin/bash

BASEDIR=$1
ERRORS=0

echo "Checking policy paths for consistency..."
readarray -t files < <(find "$BASEDIR" -name '*.yaml')
for file in "${files[@]}"; do
  readarray -t references < <(grep -e 'path:' -e 'fileName:' "$file" | grep -v schema.openapi | cut -d ':' -f 2 | sed 's/ *#.*$//' | grep 'yaml$' | sed 's/^ *//' | sed 's|source-crs/||')
  for ref in "${references[@]}"; do
    if [[ ! -f "source-crs/$ref" ]]; then
      echo "  $file: Misplaced reference to $ref"
      ERRORS=$((ERRORS + 1))
    fi
  done
done

if [[ $ERRORS -eq 0 ]]; then
  echo "  OK"
  exit 0
fi
exit 1
