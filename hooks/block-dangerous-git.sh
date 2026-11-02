#!/bin/bash

# PreToolUse hook: blocks dangerous git and gh CLI commands.
# Exits 2 with a BLOCKED message on stderr when any segment of the Bash
# command matches a block pattern, and 0 otherwise.
#
# The command is split into segments on newlines, ;, &, &&, |, ||, (, $( and
# backticks, so an allowed segment can't carry a blocked one. Patterns are
# anchored to the start of a segment, after any VAR=value assignments or a
# sudo/command/env/exec/if/then style prefix, so text that only mentions a
# command (a commit message, a grep argument) doesn't match.
#
# Customization. Anything that weakens the guard is read only from the env
# block of the user settings file (~/.claude/settings.json, or
# $CLAUDE_CONFIG_DIR/settings.json), never from the process environment or
# project settings, which the agent can write:
#   GIT_GUARDRAILS_DISABLE         "1" skips the hook.
#   GIT_GUARDRAILS_ALLOW_PATTERNS  Newline-separated ERE. A segment matching
#                                  one is allowed even if a block pattern matches.
# Extra blocks may come from anywhere:
#   GIT_GUARDRAILS_EXTRA_PATTERNS  Newline-separated ERE added to the block list,
#                                  from the process environment or the user
#                                  settings env block.
# The hook fails closed: missing jq, unparseable input, or an invalid pattern
# exits 2.

blocked() {
  echo "BLOCKED: $1 The user has prevented you from doing this." >&2
  exit 2
}

if ! command -v jq >/dev/null 2>&1; then
  blocked "git-guardrails needs jq to read the hook input and it is not on PATH. Install jq (brew install jq) or disable the plugin."
fi

INPUT=$(cat)
if ! COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null); then
  blocked "git-guardrails could not parse the hook input as JSON."
fi
[ -n "$COMMAND" ] || exit 0

USER_SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
user_setting() {
  [ -f "$USER_SETTINGS" ] || return 0
  jq -r --arg k "$1" '.env[$k] // empty | strings' "$USER_SETTINGS" 2>/dev/null
}

[ "$(user_setting GIT_GUARDRAILS_DISABLE)" = "1" ] && exit 0

ALLOW=()
EXTRA=()
while IFS= read -r line; do
  [ -n "$line" ] && ALLOW+=("$line")
done <<< "$(user_setting GIT_GUARDRAILS_ALLOW_PATTERNS)"
while IFS= read -r line; do
  [ -n "$line" ] && EXTRA+=("$line")
done <<< "${GIT_GUARDRAILS_EXTRA_PATTERNS:-$(user_setting GIT_GUARDRAILS_EXTRA_PATTERNS)}"

validate_patterns() {
  local name="$1"
  shift
  local p
  for p in "$@"; do
    [[ "" =~ $p ]]
    if [ $? -eq 2 ]; then
      blocked "'$p' in $name is not a valid extended regular expression."
    fi
  done
}
validate_patterns GIT_GUARDRAILS_ALLOW_PATTERNS "${ALLOW[@]}"
validate_patterns GIT_GUARDRAILS_EXTRA_PATTERNS "${EXTRA[@]}"

# Regex building blocks (POSIX ERE, matched with [[ =~ ]]).
S='[[:space:]]'
TOKEN='[^[:space:];&|]+'
OPT="($S+-[^[:space:]]+($S+[^[:space:]-][^[:space:]]*)?)*"
PREFIX="^$S*(([^[:space:]=]+=[^[:space:]]*|sudo|command|exec|env|nohup|time|xargs|nice|if|then|else|elif|do|while|until|\\{|!)$OPT$S+)*"
GIT="${PREFIX}git$OPT$S+"
GH="${PREFIX}gh$S+"
ARGS="($S+$TOKEN)*$S+"
END='([[:space:]]|$|[;&|)])'
METHOD='(DELETE|POST|PUT|PATCH|delete|post|put|patch)'

LABEL=()
BLOCK=()
add() { LABEL+=("$1"); BLOCK+=("$2"); }

add "git push"               "${GIT}push${END}"
add "git reset --hard"       "${GIT}reset${ARGS}--hard${END}"
add "git clean -f"           "${GIT}clean${ARGS}(-[a-zA-Z]*f[a-zA-Z]*|--force)${END}"
add "git branch -D"          "${GIT}branch${ARGS}(-[a-zA-Z]*D[a-zA-Z]*|--delete${S}+--force|--force${S}+--delete)${END}"
add "git checkout/restore ." "${GIT}(checkout|restore)${ARGS}\\.${END}"

add "gh repo delete/archive/rename/edit" "${GH}repo${S}+(delete|archive|rename|edit)${END}"
add "gh repo deploy-key add/delete"      "${GH}repo${S}+deploy-key${S}+(add|delete)${END}"
add "gh release create/delete"           "${GH}release${S}+(create|delete|delete-asset)${END}"
add "gh issue delete/close/lock/comment" "${GH}issue${S}+(delete|close|lock|comment)${END}"
add "gh pr merge/close/review/comment"   "${GH}pr${S}+(merge|close|review|comment)${END}"
add "gh secret set/delete"               "${GH}secret${S}+(set|delete)${END}"
add "gh variable set/delete"             "${GH}variable${S}+(set|delete)${END}"
add "gh codespace delete"                "${GH}codespace${S}+delete${END}"
add "gh workflow run"                    "${GH}workflow${S}+run${END}"
add "gh api mutation"                    "${GH}api${ARGS}((-X|--method)(=|$S*)${METHOD}|(-[fF]|--field|--raw-field|--input)(=|$S|$))"

check_segment() {
  local seg="$1" p i
  [ -n "${seg//[[:space:]]/}" ] || return 0
  for p in "${ALLOW[@]}"; do
    [[ "$seg" =~ $p ]] && return 0
  done
  for ((i = 0; i < ${#BLOCK[@]}; i++)); do
    if [[ "$seg" =~ ${BLOCK[$i]} ]]; then
      blocked "'$seg' matches dangerous pattern: ${LABEL[$i]}."
    fi
  done
  for p in "${EXTRA[@]}"; do
    if [[ "$seg" =~ $p ]]; then
      blocked "'$seg' matches custom pattern '$p' from GIT_GUARDRAILS_EXTRA_PATTERNS."
    fi
  done
}

nl=$'\n'
segments="$COMMAND"
for sep in '&&' '||' '$(' '`' ';' '&' '|' '('; do
  segments="${segments//"$sep"/$nl}"
done
while IFS= read -r seg; do
  check_segment "$seg"
done <<< "$segments"

exit 0
