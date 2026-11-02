#!/usr/bin/env bash
# Resolves the docs-vault settings from the env block of the Claude Code
# settings files, in Claude Code's precedence order: .claude/settings.local.json,
# then .claude/settings.json (under the project root), then ~/.claude/settings.json.
# A key no file sets falls back to the process environment. The project root is
# CLAUDE_PROJECT_DIR, else the git root of the current directory, else the
# current directory. Source it and call docs_vault_resolve, or run it directly
# to print the resolved values.
#
# Sets and exports:
#   DOCS_VAULT                absolute vault path, empty when unconfigured
#   DOCS_VAULT_GUARD          "on" (default) or "off"
#   DOCS_VAULT_EXTRA_PATTERNS colon-separated extra globs for the guard

docs_vault_project_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  local top=""
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || top=""
  printf '%s' "${top:-$PWD}"
}

docs_vault_setting() {
  local key="$1" val="" f
  if command -v jq >/dev/null 2>&1; then
    local project config_dir
    project="$(docs_vault_project_dir)"
    config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    for f in "$project/.claude/settings.local.json" "$project/.claude/settings.json" "$config_dir/settings.json"; do
      [ -f "$f" ] || continue
      val="$(jq -r --arg k "$key" '.env[$k] // empty | strings' "$f" 2>/dev/null)"
      if [ -n "$val" ]; then
        printf '%s' "$val"
        return 0
      fi
    done
  fi
  printf '%s' "${!key:-}"
}

docs_vault_expand_home() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#\~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

docs_vault_resolve() {
  DOCS_VAULT="$(docs_vault_expand_home "$(docs_vault_setting DOCS_VAULT)")"
  DOCS_VAULT="${DOCS_VAULT%/}"
  DOCS_VAULT_GUARD="$(docs_vault_setting DOCS_VAULT_GUARD)"
  DOCS_VAULT_GUARD="${DOCS_VAULT_GUARD:-on}"
  DOCS_VAULT_EXTRA_PATTERNS="$(docs_vault_setting DOCS_VAULT_EXTRA_PATTERNS)"
  export DOCS_VAULT DOCS_VAULT_GUARD DOCS_VAULT_EXTRA_PATTERNS
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  command -v jq >/dev/null 2>&1 || echo "resolve-vault.sh: jq not found; settings files were not read" >&2
  docs_vault_resolve
  printf 'DOCS_VAULT=%s\nDOCS_VAULT_GUARD=%s\nDOCS_VAULT_EXTRA_PATTERNS=%s\n' \
    "$DOCS_VAULT" "$DOCS_VAULT_GUARD" "$DOCS_VAULT_EXTRA_PATTERNS"
fi
