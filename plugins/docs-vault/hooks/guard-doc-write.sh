#!/usr/bin/env bash
# PreToolUse (Write|Edit|MultiEdit): denies generated documentation written
# to a known skill-default path outside the docs vault, with a reason that
# tells the agent where to re-issue the write.
#
# Blocks, when the path is not under DOCS_VAULT:
#   - basename UBIQUITOUS_LANGUAGE.md
#   - any path containing /docs/superpowers/
#   - a .md path with a /plans/, /specs/, or /test-plans/ segment
#   - any glob listed in DOCS_VAULT_EXTRA_PATTERNS (colon-separated)
# Everything else passes. A path containing a .. segment is never treated as
# inside the vault. Exits 0 with no output when DOCS_VAULT is unset,
# DOCS_VAULT_GUARD is "off", or jq is missing.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/resolve-vault.sh"

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

docs_vault_resolve
[ -n "$DOCS_VAULT" ] || exit 0
[ "$DOCS_VAULT_GUARD" != "off" ] || exit 0

tool="$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)"

case "$tool" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac
[ -n "$path" ] || exit 0

# A path with a .. segment never counts as inside the vault.
case "$path" in
  *"/../"*|*"/..") ;;
  "$DOCS_VAULT"|"$DOCS_VAULT"/*) exit 0 ;;
esac

hit=0
base="${path##*/}"
if [ "$base" = "UBIQUITOUS_LANGUAGE.md" ]; then
  hit=1
elif [[ "$path" == */docs/superpowers/* ]]; then
  hit=1
elif [[ "$path" == *.md && ( "$path" == */plans/* || "$path" == */specs/* || "$path" == */test-plans/* ) ]]; then
  hit=1
fi

if [ "$hit" -eq 0 ] && [ -n "$DOCS_VAULT_EXTRA_PATTERNS" ]; then
  IFS=':' read -r -a extra <<< "$DOCS_VAULT_EXTRA_PATTERNS"
  for glob in "${extra[@]}"; do
    [ -n "$glob" ] || continue
    if [[ "$path" == $glob ]]; then
      hit=1
      break
    fi
  done
fi
[ "$hit" -eq 1 ] || exit 0

reason="Blocked: this looks like generated documentation being written outside the docs vault ($path).

Durable docs (plans, specs, PRDs, test plans, triage, RFCs, glossaries, blueprints) belong in the docs vault at $DOCS_VAULT, not in a code repo or a skill-default ./plans, ./specs, ./test-plans, or docs/superpowers path.

Re-issue this write into the vault:
1. Read $DOCS_VAULT/AGENTS.md first (or load the docs-vault:vault-conventions skill).
2. Put the file in the matching folder: plans/ specs/ prds/ test-plans/ triage/ reference/ scratch/.
3. Name it YYYY-MM-DD-<issue-key>-<slug>-<type>.md and add the frontmatter and MOC links AGENTS.md requires.

If this file is meant to stay in the repo, set DOCS_VAULT_GUARD to \"off\" in the env block of this project's .claude/settings.json."

jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
