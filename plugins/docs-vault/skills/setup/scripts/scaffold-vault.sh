#!/usr/bin/env bash
# Creates the vault folder layout and copies the bundled AGENTS.md template.
#
# Usage: scaffold-vault.sh <vault-path>
# Existing folders are left alone and an existing AGENTS.md is never
# overwritten. Prints what it created and the absolute vault path.

set -euo pipefail

[ "$#" -eq 1 ] && [ -n "$1" ] || { echo "usage: scaffold-vault.sh <vault-path>" >&2; exit 1; }
vault="$1"
case "$vault" in
  "~") vault="$HOME" ;;
  "~/"*) vault="$HOME/${vault#\~/}" ;;
esac
case "$vault" in
  /*) ;;
  *) vault="$PWD/$vault" ;;
esac
vault="${vault%/}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
template="$PLUGIN_ROOT/templates/AGENTS.md"
[ -f "$template" ] || { echo "scaffold-vault.sh: template missing at $template" >&2; exit 1; }

created=()
for dir in prds specs plans test-plans triage reference maps scratch; do
  if [ ! -d "$vault/$dir" ]; then
    mkdir -p "$vault/$dir"
    created+=("$dir/")
  fi
done

if [ -f "$vault/AGENTS.md" ]; then
  echo "kept existing AGENTS.md"
else
  cp "$template" "$vault/AGENTS.md"
  created+=("AGENTS.md")
fi

if [ "${#created[@]}" -gt 0 ]; then
  echo "created: ${created[*]}"
else
  echo "nothing to create"
fi
echo "$vault"
