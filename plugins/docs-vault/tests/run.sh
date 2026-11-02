#!/usr/bin/env bash
# Exercises the docs-vault hooks and setup scripts against a temporary HOME,
# project, and vault. Prints one line per case and exits non-zero on failure.

set -u
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
T="$(cd "$T" && pwd -P)"
trap 'rm -rf "$T"' EXIT

export HOME="$T/home"
PROJ="$T/proj"
VAULT="$T/vault"
mkdir -p "$HOME/.claude" "$PROJ/.claude"
unset DOCS_VAULT DOCS_VAULT_GUARD DOCS_VAULT_EXTRA_PATTERNS CLAUDE_CONFIG_DIR
export CLAUDE_PROJECT_DIR="$PROJ"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "ok   $1"; }
bad() { fail=$((fail + 1)); echo "FAIL $1: $2"; }

resolve() { bash "$PLUGIN_ROOT/hooks/lib/resolve-vault.sh"; }
guard() {
  jq -nc --arg t "$1" --arg p "$2" '{tool_name:$t, tool_input:{file_path:$p}}' \
    | bash "$PLUGIN_ROOT/hooks/guard-doc-write.sh"
}
is_deny() { printf '%s' "$1" | jq -e '.hookSpecificOutput.permissionDecision=="deny"' >/dev/null 2>&1; }
expect_deny() {
  local out
  out="$(guard "$1" "$2")"
  if is_deny "$out"; then ok "deny  $1 $2"; else bad "deny  $1 $2" "got: ${out:-<empty>}"; fi
}
expect_allow() {
  local out
  out="$(guard "$1" "$2")"
  if [ -z "$out" ]; then ok "allow $1 $2"; else bad "allow $1 $2" "got: $out"; fi
}
user_settings() { printf '%s' "$1" > "$HOME/.claude/settings.json"; }
project_settings() { printf '%s' "$1" > "$PROJ/.claude/settings.json"; }
local_settings() { printf '%s' "$1" > "$PROJ/.claude/settings.local.json"; }
clear_settings() { rm -f "$HOME/.claude/settings.json" "$PROJ/.claude/settings.json" "$PROJ/.claude/settings.local.json"; }

echo "# resolver"
clear_settings
r="$(resolve)"
[ "$r" = $'DOCS_VAULT=\nDOCS_VAULT_GUARD=on\nDOCS_VAULT_EXTRA_PATTERNS=' ] && ok "unconfigured: empty path, guard on" || bad "unconfigured" "$r"
user_settings '{"env":{"DOCS_VAULT":"~/vault-user/"}}'
r="$(resolve | sed -n 1p)"
[ "$r" = "DOCS_VAULT=$HOME/vault-user" ] && ok "user setting; tilde expanded; trailing slash stripped" || bad "user setting" "$r"
project_settings '{"env":{"DOCS_VAULT":"/p/vault"}}'
r="$(resolve | sed -n 1p)"
[ "$r" = "DOCS_VAULT=/p/vault" ] && ok "project beats user" || bad "project beats user" "$r"
local_settings '{"env":{"DOCS_VAULT":"/l/vault","DOCS_VAULT_GUARD":"off"}}'
r="$(resolve)"
[ "$(echo "$r" | sed -n 1p)" = "DOCS_VAULT=/l/vault" ] && [ "$(echo "$r" | sed -n 2p)" = "DOCS_VAULT_GUARD=off" ] && ok "local beats project; guard read from local" || bad "local beats project" "$r"
r="$(DOCS_VAULT=/e/vault resolve | sed -n 1p)"
[ "$r" = "DOCS_VAULT=/l/vault" ] && ok "settings file beats process env" || bad "file beats env" "$r"
printf 'not json' > "$PROJ/.claude/settings.local.json"
r="$(resolve | sed -n 1p)"
[ "$r" = "DOCS_VAULT=/p/vault" ] && ok "invalid local file skipped" || bad "invalid local file" "$r"
user_settings '{"model":"x"}'
rm -f "$PROJ/.claude/settings.json" "$PROJ/.claude/settings.local.json"
r="$(resolve | sed -n 1p)"
[ "$r" = "DOCS_VAULT=" ] && ok "settings file without env block" || bad "no env block" "$r"
user_settings '{"env":{"DOCS_VAULT":["a"],"DOCS_VAULT_GUARD":false}}'
r="$(resolve)"
[ "$r" = $'DOCS_VAULT=\nDOCS_VAULT_GUARD=on\nDOCS_VAULT_EXTRA_PATTERNS=' ] && ok "non-string env values ignored" || bad "non-string values" "$r"
clear_settings
r="$(DOCS_VAULT=/e/vault resolve | sed -n 1p)"
[ "$r" = "DOCS_VAULT=/e/vault" ] && ok "process env used when no file sets the key" || bad "env fallback" "$r"
git -C "$PROJ" init -q >/dev/null 2>&1
mkdir -p "$PROJ/sub"
project_settings '{"env":{"DOCS_VAULT":"/p/vault"}}'
r="$(cd "$PROJ/sub" && env -u CLAUDE_PROJECT_DIR bash "$PLUGIN_ROOT/hooks/lib/resolve-vault.sh" 2>/dev/null | sed -n 1p)"
[ "$r" = "DOCS_VAULT=/p/vault" ] && ok "project root found through git when CLAUDE_PROJECT_DIR is unset" || bad "git root" "$r"
rm "$PROJ/.claude/settings.json"

echo "# guard"
clear_settings
expect_allow Write /repo/plans/x.md
user_settings "{\"env\":{\"DOCS_VAULT\":\"$VAULT\"}}"
expect_allow Write "$VAULT/plans/x.md"
expect_allow Write "$VAULT"
expect_deny Write /repo/plans/x.md
expect_deny Edit /repo/plans/x.md
expect_deny MultiEdit /repo/specs/x.md
expect_deny Write /repo/test-plans/x.md
expect_deny Write /repo/docs/superpowers/plans/x.md
expect_deny Write /repo/UBIQUITOUS_LANGUAGE.md
expect_deny Write "${VAULT}2/plans/x.md"
expect_allow Write /repo/plans/x.ts
expect_allow Write /repo/src/foo.ts
expect_allow Write /repo/docs/guide/x.md
expect_allow Write /repo/README.md
expect_allow Read /repo/plans/x.md
out="$(guard Write /repo/plans/x.md)"
printf '%s' "$out" | jq -e --arg v "$VAULT" '.hookSpecificOutput.permissionDecisionReason | contains($v) and contains("/repo/plans/x.md") and contains("AGENTS.md")' >/dev/null \
  && ok "deny reason names the vault, the path, and AGENTS.md" || bad "deny reason" "$out"
project_settings '{"env":{"DOCS_VAULT_GUARD":"off"}}'
expect_allow Write /repo/plans/x.md
rm "$PROJ/.claude/settings.json"
project_settings '{"env":{"DOCS_VAULT_EXTRA_PATTERNS":"*/adr/*.md:*/rfcs/*"}}'
expect_deny Write /repo/adr/0001.md
expect_deny Write /repo/rfcs/x.txt
expect_allow Write /repo/adr/notes.txt
rm "$PROJ/.claude/settings.json"
expect_deny Write "$VAULT/../repo/plans/x.md"
out="$(printf '' | bash "$PLUGIN_ROOT/hooks/guard-doc-write.sh")"
[ -z "$out" ] && ok "empty stdin passes" || bad "empty stdin" "$out"
out="$(printf 'garbage' | bash "$PLUGIN_ROOT/hooks/guard-doc-write.sh")"
[ -z "$out" ] && ok "non-JSON stdin passes" || bad "non-JSON stdin" "$out"

echo "# session-start"
clear_settings
out="$(bash "$PLUGIN_ROOT/hooks/session-start.sh")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName=="SessionStart" and (.hookSpecificOutput.additionalContext|contains("/docs-vault:setup"))' >/dev/null \
  && ok "unconfigured: valid JSON, prompts setup" || bad "unconfigured session" "$out"
user_settings "{\"env\":{\"DOCS_VAULT\":\"$VAULT\"}}"
out="$(bash "$PLUGIN_ROOT/hooks/session-start.sh")"
printf '%s' "$out" | jq -e --arg v "$VAULT" '.hookSpecificOutput.additionalContext | contains($v) and contains("AGENTS.md") and contains("PreToolUse hook denies")' >/dev/null \
  && ok "configured: names vault, AGENTS.md, guard" || bad "configured session" "$out"
local_settings '{"env":{"DOCS_VAULT_GUARD":"off"}}'
out="$(bash "$PLUGIN_ROOT/hooks/session-start.sh")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("guard hook is off")' >/dev/null \
  && ok "guard off: noted in context" || bad "guard off session" "$out"

echo "# write-config"
clear_settings
WC="$PLUGIN_ROOT/skills/setup/scripts/write-config.sh"
user_settings '{"model":"opus","env":{"FOO":"1"},"permissions":{"allow":["Bash(ls)"]}}'
f="$(bash "$WC" user DOCS_VAULT="~/my docs/")"
[ "$f" = "$HOME/.claude/settings.json" ] && jq -e --arg h "$HOME" '.model=="opus" and .env.FOO=="1" and .permissions.allow==["Bash(ls)"] and .env.DOCS_VAULT==($h+"/my docs")' "$f" >/dev/null \
  && ok "user scope: other keys kept; tilde expanded; slash stripped; space kept" || bad "user scope" "$(cat "$f")"
f="$(cd "$PROJ" && bash "$WC" project DOCS_VAULT=rel/vault DOCS_VAULT_GUARD=off)"
[ "$f" = "$PROJ/.claude/settings.json" ] && jq -e --arg p "$PROJ" '.env.DOCS_VAULT==($p+"/rel/vault") and .env.DOCS_VAULT_GUARD=="off"' "$f" >/dev/null \
  && ok "project scope: file created; relative path resolved; two keys" || bad "project scope" "$(cat "$f" 2>/dev/null)"
f="$(bash "$WC" local DOCS_VAULT_EXTRA_PATTERNS='*/adr/*.md')"
[ "$f" = "$PROJ/.claude/settings.local.json" ] && jq -e '.env.DOCS_VAULT_EXTRA_PATTERNS=="*/adr/*.md" and (.env.DOCS_VAULT|not)' "$f" >/dev/null \
  && ok "local scope: extra patterns only" || bad "local scope" "$(cat "$f")"
f="$(cd "$PROJ/sub" && env -u CLAUDE_PROJECT_DIR bash "$WC" project DOCS_VAULT_GUARD=on)"
[ "$f" = "$PROJ/.claude/settings.json" ] && jq -e '.env.DOCS_VAULT_GUARD=="on"' "$f" >/dev/null \
  && ok "project scope from a subdirectory resolves to the git root" || bad "project from subdir" "$f"
if bash "$WC" user DOCS_VAULT_GUARD=maybe 2>/dev/null; then bad "guard validation" "accepted maybe"; else ok "guard value validated"; fi
if bash "$WC" user FOO=bar 2>/dev/null; then bad "unknown key" "accepted FOO"; else ok "unknown key refused"; fi
if bash "$WC" nowhere DOCS_VAULT=/x 2>/dev/null; then bad "scope validation" "accepted nowhere"; else ok "unknown scope refused"; fi
if bash "$WC" user 2>/dev/null; then bad "arg validation" "accepted no key"; else ok "missing key refused"; fi
printf '{broken' > "$HOME/.claude/settings.json"
if bash "$WC" user DOCS_VAULT=/x 2>/dev/null; then
  bad "invalid json" "wrote anyway"
elif [ "$(cat "$HOME/.claude/settings.json")" = '{broken' ]; then
  ok "invalid json refused; file untouched"
else
  bad "invalid json" "file changed"
fi
if ls "$HOME/.claude/" | grep -q 'settings\.json\.'; then bad "temp cleanup" "leftover temp file"; else ok "no temp files left behind"; fi

echo "# scaffold"
SC="$PLUGIN_ROOT/skills/setup/scripts/scaffold-vault.sh"
out="$(bash "$SC" "$VAULT")"
missing=""
for d in prds specs plans test-plans triage reference maps scratch; do
  [ -d "$VAULT/$d" ] || missing="$missing $d"
done
if [ -z "$missing" ] && cmp -s "$VAULT/AGENTS.md" "$PLUGIN_ROOT/templates/AGENTS.md" && [ "$(echo "$out" | tail -1)" = "$VAULT" ]; then
  ok "new vault: eight folders and AGENTS.md"
else
  bad "new vault" "missing:$missing out: $out"
fi
printf 'custom' > "$VAULT/AGENTS.md"
out="$(bash "$SC" "$VAULT")"
if [ "$(cat "$VAULT/AGENTS.md")" = "custom" ] && echo "$out" | grep -q "kept existing" && echo "$out" | grep -q "nothing to create"; then
  ok "existing vault: AGENTS.md and folders untouched"
else
  bad "existing vault" "$out"
fi
out="$(cd "$T" && bash "$SC" "~/tilde-vault" | tail -1)"
[ "$out" = "$HOME/tilde-vault" ] && [ -d "$HOME/tilde-vault/maps" ] && ok "tilde path expanded" || bad "tilde path" "$out"
if bash "$SC" 2>/dev/null; then bad "scaffold args" "accepted no path"; else ok "missing path refused"; fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
