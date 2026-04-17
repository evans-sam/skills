---
name: git-guardrails-claude-code
description: Explain what the plugin-shipped git-guardrails PreToolUse hook blocks and how to customize it. Use when user asks what git/gh commands are blocked, why a Bash command was refused with a BLOCKED message, how to add or allow patterns, or how to disable the guardrails.
---

# Git & GitHub CLI Guardrails

This plugin ships a `PreToolUse` hook that intercepts and blocks dangerous `git` and `gh` CLI commands before Claude Code executes them. The hook is wired up automatically when you install the plugin — there is no manual setup step.

The script lives at [hooks/block-dangerous-git.sh](../../hooks/block-dangerous-git.sh) and is registered via [hooks/hooks.json](../../hooks/hooks.json).

When a command matches a dangerous pattern, the hook exits with code `2` and prints a `BLOCKED:` message to stderr. Claude Code surfaces this to the assistant as a refusal.

## What Gets Blocked

### Git commands

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
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
- `gh api -X DELETE|POST|PUT|PATCH`
- `gh api --method DELETE|POST|PUT|PATCH`

## Customization (via environment variables)

The hook reads three env vars at invocation time. Set them in your shell profile (`~/.zshrc`, `~/.bashrc`) so Claude Code inherits them, or in a project-local `.envrc` if you use `direnv`.

### `GIT_GUARDRAILS_EXTRA_PATTERNS`

Newline-separated list of additional regex patterns to block.

```bash
export GIT_GUARDRAILS_EXTRA_PATTERNS='terraform destroy
kubectl delete'
```

### `GIT_GUARDRAILS_ALLOW_PATTERNS`

Newline-separated list of regex patterns to allow, bypassing the default block list. Useful if you want to permit a specific command that would otherwise be blocked.

```bash
export GIT_GUARDRAILS_ALLOW_PATTERNS='gh pr comment --body'
```

### `GIT_GUARDRAILS_DISABLE`

Set to `1` to disable the hook entirely.

```bash
export GIT_GUARDRAILS_DISABLE=1
```

## Verifying the hook

To confirm the hook is wired up and working:

```bash
echo '{"tool_input":{"command":"git push origin main"}}' \
  | "${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/cache/claude-plugins-official/skills/*/}/hooks/block-dangerous-git.sh"
```

It should exit with code `2` and print a `BLOCKED:` line to stderr.

Inside a Claude Code session, asking the assistant to run `git push` should produce the same refusal.
