#!/bin/bash

# PreToolUse hook: blocks dangerous git and gh CLI commands.
# Exits 2 with a BLOCKED message to stderr when the Bash command matches a pattern.
#
# Customization via environment variables:
#   GIT_GUARDRAILS_DISABLE         If set to "1", the hook exits 0 without checking anything.
#   GIT_GUARDRAILS_EXTRA_PATTERNS  Newline-separated regex patterns to ADD to the block list.
#   GIT_GUARDRAILS_ALLOW_PATTERNS  Newline-separated regex patterns to ALLOW (bypass block
#                                  even if a default pattern would match).

if [ "$GIT_GUARDRAILS_DISABLE" = "1" ]; then
  exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

DANGEROUS_GIT_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

DANGEROUS_GH_PATTERNS=(
  "gh repo delete"
  "gh repo archive"
  "gh repo rename"
  "gh repo edit"
  "gh release delete"
  "gh release delete-asset"
  "gh issue delete"
  "gh issue close"
  "gh issue lock"
  "gh pr merge"
  "gh pr close"
  "gh pr review"
  "gh pr comment"
  "gh issue comment"
  "gh secret delete"
  "gh secret set"
  "gh variable delete"
  "gh variable set"
  "gh codespace delete"
  "gh repo deploy-key delete"
  "gh repo deploy-key add"
  "gh workflow run"
  "gh release create"
  "gh api -X DELETE"
  "gh api -X POST"
  "gh api -X PUT"
  "gh api -X PATCH"
  "gh api --method DELETE"
  "gh api --method POST"
  "gh api --method PUT"
  "gh api --method PATCH"
)

if [ -n "$GIT_GUARDRAILS_ALLOW_PATTERNS" ]; then
  while IFS= read -r allow_pattern; do
    [ -z "$allow_pattern" ] && continue
    if echo "$COMMAND" | grep -qE "$allow_pattern"; then
      exit 0
    fi
  done <<< "$GIT_GUARDRAILS_ALLOW_PATTERNS"
fi

check_patterns() {
  local label="$1"
  shift
  for pattern in "$@"; do
    if echo "$COMMAND" | grep -qE "$pattern"; then
      echo "BLOCKED: '$COMMAND' matches dangerous $label pattern '$pattern'. The user has prevented you from doing this." >&2
      exit 2
    fi
  done
}

check_patterns "git" "${DANGEROUS_GIT_PATTERNS[@]}"
check_patterns "gh CLI" "${DANGEROUS_GH_PATTERNS[@]}"

if [ -n "$GIT_GUARDRAILS_EXTRA_PATTERNS" ]; then
  while IFS= read -r extra_pattern; do
    [ -z "$extra_pattern" ] && continue
    if echo "$COMMAND" | grep -qE "$extra_pattern"; then
      echo "BLOCKED: '$COMMAND' matches custom pattern '$extra_pattern' from GIT_GUARDRAILS_EXTRA_PATTERNS. The user has prevented you from doing this." >&2
      exit 2
    fi
  done <<< "$GIT_GUARDRAILS_EXTRA_PATTERNS"
fi

exit 0
