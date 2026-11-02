#!/usr/bin/env bash
# SessionStart: injects the docs-vault rule and the resolved vault path as
# context, or a one-line setup prompt when no vault is configured.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/resolve-vault.sh"

command -v jq >/dev/null 2>&1 || exit 0
docs_vault_resolve

if [ -z "$DOCS_VAULT" ]; then
  context="<docs-vault>
The docs-vault plugin is installed but no vault path is configured, so the doc guard is inactive. Before writing durable documentation (a plan, spec, PRD, test plan, triage write-up, RFC, or glossary), ask the user to run /docs-vault:setup <path>.
</docs-vault>"
else
  guard_line="A PreToolUse hook denies .md writes to skill-default paths (plans/, specs/, test-plans/, docs/superpowers/, UBIQUITOUS_LANGUAGE.md) outside the vault."
  if [ "$DOCS_VAULT_GUARD" = "off" ]; then
    guard_line="The doc guard hook is off for this project (DOCS_VAULT_GUARD=off); the rule above still applies."
  fi
  context="<docs-vault>
Durable documentation goes in the docs vault at $DOCS_VAULT: plans, specs, PRDs, RFCs, test plans, triage write-ups, glossaries, blueprints, design docs, anything meant to outlive this session. This overrides every skill's default save location. If a skill would write a doc into a code repo and commit it, write it to the vault instead and don't commit. If a skill would open a GitHub or Linear issue for the doc body, write the file to the vault and let the issue link it. If a skill asks which directory to use, don't ask: the vault is the answer.

Before writing to the vault, read $DOCS_VAULT/AGENTS.md and follow its layout, naming, frontmatter, and linking rules. If that file is missing, load the docs-vault:vault-conventions skill.

$guard_line
</docs-vault>"
fi

jq -n --arg c "$context" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
exit 0
