---
name: git-guardrails-claude-code
description: Explain what the plugin-shipped git-guardrails PreToolUse hook blocks and how to customize it. Use when user asks what git/gh commands are blocked, why a Bash command was refused with a BLOCKED message, how to add or allow patterns, or how to disable the guardrails.
---

# Git & GitHub CLI Guardrails

This plugin ships a `PreToolUse` hook that intercepts and blocks dangerous `git` and `gh` CLI commands before Claude Code executes them. The hook is wired up automatically when you install the plugin; there is no manual setup step.

The script lives at [hooks/block-dangerous-git.sh](../../hooks/block-dangerous-git.sh) and is registered via [hooks/hooks.json](../../hooks/hooks.json).

When a command matches a dangerous pattern, the hook exits with code `2` and prints a `BLOCKED:` message to stderr. Claude Code surfaces this to the assistant as a refusal.

## How matching works

The Bash command is split into segments on newlines, `;`, `&`, `&&`, `|`, `||`, `(`, `$(` and backticks, and every segment is checked on its own. A pattern matches only at the start of a segment, after any `VAR=value` assignments or a prefix such as `sudo`, `env`, `command`, `exec`, `if` or `then`, and after git's own global options (`git -C <dir> push` is still `git push`). A commit message or a `--grep` argument that merely contains the words does not match.

## What Gets Blocked

### Git commands

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` (any flag combination containing `f`, or `--force`)
- `git branch -D` (or `--delete --force`)
- `git checkout .` / `git restore .`

### GitHub CLI (`gh`) commands

**Destructive operations:**
- `gh repo delete` / `gh repo archive` / `gh repo rename` / `gh repo edit`
- `gh release delete` / `gh release delete-asset`
- `gh issue delete`
- `gh codespace delete`
- `gh repo deploy-key delete`

**Shared-state modifications (visible to others):**
- `gh pr merge` / `gh pr close` / `gh pr review` / `gh pr comment`
- `gh issue close` / `gh issue lock` / `gh issue comment`
- `gh release create`
- `gh workflow run`

**Secret and variable management:**
- `gh secret set` / `gh secret delete`
- `gh variable set` / `gh variable delete`
- `gh repo deploy-key add`

**Raw API mutations:**
- `gh api` with `-X` or `--method` set to `DELETE`, `POST`, `PUT` or `PATCH`, in any position
- `gh api` with `-f`, `-F`, `--field`, `--raw-field` or `--input`, which make an implicit `POST`

## Customization

Settings go in the `env` block of a Claude Code settings file. Shell exports in `~/.zshrc` or an `.envrc` don't reach the hook from the desktop app or IDE extensions, which don't start from a login shell.

Anything that weakens the guard is read only from the user settings file, `~/.claude/settings.json` (or `$CLAUDE_CONFIG_DIR/settings.json`). The hook ignores those keys in the process environment and in project settings, because the agent it guards can write a project's `.claude/settings.json`.

```json
{
  "env": {
    "GIT_GUARDRAILS_ALLOW_PATTERNS": "gh pr comment --body",
    "GIT_GUARDRAILS_EXTRA_PATTERNS": "terraform destroy\nkubectl delete"
  }
}
```

### `GIT_GUARDRAILS_EXTRA_PATTERNS`

Newline-separated extended regular expressions added to the block list. Read from the user settings file or from the process environment, since adding a block can't weaken the guard. Each pattern is tested against each segment of the command.

### `GIT_GUARDRAILS_ALLOW_PATTERNS`

Newline-separated extended regular expressions. A segment that matches one is allowed even if a block pattern also matches it. The allow applies to that segment only: `gh pr comment --body hi && git push` is still blocked on the second segment. Read from the user settings file only.

### `GIT_GUARDRAILS_DISABLE`

Set to `"1"` in the user settings file to skip the hook entirely. Read from the user settings file only. To turn the hook off for one project, disable the plugin there instead.

An invalid regular expression in either list blocks every command with a message naming the bad pattern, so a typo can't silently switch a rule off. The hook also refuses every command when `jq` is missing, since it can't read the tool input without it.

## Verifying the hook

From inside a Claude Code session with the plugin enabled:

```bash
echo '{"tool_input":{"command":"git push origin main"}}' \
  | "${CLAUDE_PLUGIN_ROOT}/hooks/block-dangerous-git.sh"
```

Outside a session, `CLAUDE_PLUGIN_ROOT` is unset; use the installed copy at `~/.claude/plugins/cache/evans-sam-skills/skills/<version>/hooks/block-dangerous-git.sh` or a checkout of this repo.

It should exit with code `2` and print a `BLOCKED:` line to stderr.

Inside a Claude Code session, asking the assistant to run `git push` should produce the same refusal.
