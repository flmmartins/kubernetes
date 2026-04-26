#!/bin/bash
set -euo pipefail

MODULES_DIR="${1:-./modules}"

if [ ! -d "$MODULES_DIR" ]; then
  echo "Error: modules directory '$MODULES_DIR' not found"
  exit 1
fi

echo "Generating terraform-docs for modules in: $MODULES_DIR"

find "$MODULES_DIR" -mindepth 1 -maxdepth 1 -type d | sort | while read -r module_dir; do
  module_name=$(basename "$module_dir")

  if ! ls "$module_dir"/*.tf &>/dev/null; then
    echo "  Skipping $module_name (no .tf files found)"
    continue
  fi

  echo "  Generating docs for: $module_name"
  terraform-docs markdown \
    --output-file README.md \
    --output-mode inject \
    "$module_dir"
done

echo "Done!"