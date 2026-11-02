#!/usr/bin/env bash
# Writes docs-vault settings into the env block of a Claude Code settings file.
#
# Usage: write-config.sh <user|project|local> KEY=VALUE [KEY=VALUE ...]
#   user     ~/.claude/settings.json (or $CLAUDE_CONFIG_DIR/settings.json)
#   project  <project>/.claude/settings.json
#   local    <project>/.claude/settings.local.json
# <project> is CLAUDE_PROJECT_DIR, else the git root of the current directory,
# else the current directory.
#
# Accepted keys: DOCS_VAULT, DOCS_VAULT_GUARD, DOCS_VAULT_EXTRA_PATTERNS.
# DOCS_VAULT is stored as an absolute path. Every other key in the file is
# preserved; the file is created when missing and refused when not valid JSON.
# Prints the path of the file written.

set -euo pipefail

usage() {
  echo "usage: write-config.sh <user|project|local> KEY=VALUE [KEY=VALUE ...]" >&2
  exit 1
}

project_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  local top=""
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || top=""
  printf '%s' "${top:-$PWD}"
}

[ "$#" -ge 2 ] || usage
scope="$1"
shift
command -v jq >/dev/null 2>&1 || { echo "write-config.sh: jq is required" >&2; exit 1; }

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
case "$scope" in
  user) file="$config_dir/settings.json" ;;
  project) file="$(project_dir)/.claude/settings.json" ;;
  local) file="$(project_dir)/.claude/settings.local.json" ;;
  *) usage ;;
esac

normalize_path() {
  local p="$1"
  case "$p" in
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
  esac
  case "$p" in
    /*) ;;
    *) p="$PWD/$p" ;;
  esac
  printf '%s' "${p%/}"
}

mkdir -p "$(dirname "$file")"
if [ ! -f "$file" ]; then
  printf '{}\n' > "$file"
fi
if ! jq -e . "$file" >/dev/null 2>&1; then
  echo "write-config.sh: $file is not valid JSON; fix it before writing settings" >&2
  exit 1
fi

tmp="$(mktemp "$file.XXXXXX")"
trap 'rm -f "$tmp" "$tmp.next"' EXIT
cp "$file" "$tmp"

for kv in "$@"; do
  case "$kv" in *=*) ;; *) usage ;; esac
  key="${kv%%=*}"
  value="${kv#*=}"
  case "$key" in
    DOCS_VAULT) value="$(normalize_path "$value")" ;;
    DOCS_VAULT_GUARD)
      case "$value" in on|off) ;; *) echo "write-config.sh: DOCS_VAULT_GUARD must be on or off" >&2; exit 1 ;; esac ;;
    DOCS_VAULT_EXTRA_PATTERNS) ;;
    *) echo "write-config.sh: refusing to set unknown key $key" >&2; exit 1 ;;
  esac
  jq --arg k "$key" --arg v "$value" '.env = ((.env // {}) + {($k): $v})' "$tmp" > "$tmp.next"
  mv "$tmp.next" "$tmp"
done

mv "$tmp" "$file"
trap - EXIT
echo "$file"
