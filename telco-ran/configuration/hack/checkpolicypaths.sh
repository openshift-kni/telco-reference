#!/bin/bash

ERRORS=0

echo "Checking policy paths for consistency..."
for BASEDIR in "$@"; do
  if [[ "$BASEDIR" == "./" || "$BASEDIR" == "." ]]; then
    readarray -t files < <(find "$BASEDIR" -maxdepth 1 -name '*.yaml')
  else
    readarray -t files < <(find "$BASEDIR" -name '*.yaml')
  fi
  for file in "${files[@]}"; do
    readarray -t references < <(grep -e 'path:' -e 'fileName:' "$file" | grep -v schema.openapi | cut -d ':' -f 2 | sed 's/ *#.*$//' | grep 'yaml$' | sed 's/^ *//' | sed 's|reference-crs/||')
    for ref in "${references[@]}"; do
      if [[ ! -f "reference-crs/$ref" ]]; then
        echo "  $file: Misplaced reference to $ref"
        ERRORS=$((ERRORS + 1))
      fi
    done
  done
done

if [[ $ERRORS -eq 0 ]]; then
  echo "  OK"
  exit 0
fi
exit 1
