---
name: setup
description: This skill should be used when the user runs /docs-vault:setup, asks to "set up the docs vault", "configure the docs vault", "point docs at my vault", "change the docs vault path", "turn the doc guard off (or back on) for this repo", "let this repo keep its own plans/ folder", asks "where is my docs vault configured" or "which settings file sets DOCS_VAULT", or names DOCS_VAULT, DOCS_VAULT_GUARD, or DOCS_VAULT_EXTRA_PATTERNS. Writes those keys into the env block of a Claude Code settings file at user, project, or local scope and scaffolds the vault folders and AGENTS.md when missing. Not for writing a document into the vault; that is vault-conventions.
argument-hint: "[vault-path] [--user|--project|--local] [--guard on|off] [--extra-patterns <globs>]"
allowed-tools: Bash(bash:*), Bash(pwd), Bash(jq:*), Read, AskUserQuestion
---

# Set up the docs vault

Configure where durable documentation goes and make sure that folder is a usable vault. Settings live in the `env` block of a Claude Code settings file. The hooks and the resolver read those files directly on every call, project local over shared project over user, and use the process environment only for a key no file sets, so a change applies as soon as the file is written.

## Arguments

Invoked as `/docs-vault:setup $ARGUMENTS`. Parse the path and flags from that string; empty means nothing was passed.

- `vault-path`: the folder to use. `~` is expanded; a relative path is resolved against the current directory.
- `--user` (default): write `~/.claude/settings.json`. One vault for every project on this machine.
- `--project`: write `<project>/.claude/settings.json`. Committed and shared, so use it for `DOCS_VAULT_GUARD` and `DOCS_VAULT_EXTRA_PATTERNS`. `DOCS_VAULT` is stored as an absolute path that won't resolve on a teammate's machine; when the user asks for `--project` with a path, say so and offer `--local`.
- `--local`: write `<project>/.claude/settings.local.json`. This machine, this project only.
- `--guard on|off`: set `DOCS_VAULT_GUARD` at the chosen scope. `off` disables the PreToolUse deny wherever that scope's value wins the merge; the session rule still applies.
- `--extra-patterns <globs>`: colon-separated shell globs the guard should also deny outside the vault, for example `*/adr/*.md:*/rfcs/*`.

## Steps

1. Show the current configuration:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/resolve-vault.sh"
   ```

   If it warns that jq is missing, stop and tell the user to install jq: nothing below works without it. Otherwise an empty `DOCS_VAULT` means nothing is configured yet.

2. Determine the path, unless only `--guard` or `--extra-patterns` was given (see below). Use the argument when given. Otherwise, when step 1 printed a value, ask with AskUserQuestion whether to keep it or change it; keeping it means skipping step 4 and going to step 5. When nothing is configured, ask for a path with AskUserQuestion and offer `~/docs` as the suggested answer. Don't invent a path.

3. Determine the scope. Default to `user`. Use `project` when `--project` is given or the user scopes the request to this repo ("for this repo", "in this project", "let this repo keep its plans/"). Use `local` when `--local` is given or the user says the change is for their machine only. Never write `DOCS_VAULT_GUARD=off` at `user` scope unless the user confirms they want the guard off in every project.

4. Write the settings:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/setup/scripts/write-config.sh" <scope> DOCS_VAULT="<path>"
   ```

   Add `DOCS_VAULT_GUARD=on|off` or `DOCS_VAULT_EXTRA_PATTERNS="<globs>"` to the same call when those flags were given. For `project` or `local`, the script resolves `<project>` from `CLAUDE_PROJECT_DIR`, else the git root of the current directory, else the current directory; run `pwd` first and `cd` back to the project root if an earlier command moved away. The script prints the file it wrote; confirm that is the intended file before continuing. It preserves every other key and refuses a file that isn't valid JSON; if it refuses, show the error and stop.

5. Scaffold the vault, passing the same path string as step 4 with no `cd` in between:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/setup/scripts/scaffold-vault.sh" "<path>"
   ```

   It creates the type folders (`prds/ specs/ plans/ test-plans/ triage/ reference/ maps/ scratch/`) and copies the bundled `AGENTS.md` when the vault has none. It never overwrites an existing `AGENTS.md`.

6. Report, in a few lines: the settings file written, what the scaffold created or kept, and that the guard uses the new values from the next tool call while the session-start context appears from the next session, `/clear`, or compaction.

## Guard or pattern changes only

When the invocation carries `--guard` or `--extra-patterns` and no path, skip step 2 and step 5 and don't ask for a path. Run `write-config.sh <scope> DOCS_VAULT_GUARD=<value>` and/or `DOCS_VAULT_EXTRA_PATTERNS="<globs>"` with the scope from step 3. The common case is `--guard off --project` in a repo whose own `plans/` or `specs/` folder is intentional. When step 1 showed an empty `DOCS_VAULT`, say the guard is already inactive until a vault is configured, and write the key anyway so it holds once one is.

## Reading the result back

`resolve-vault.sh` prints the merged view. To see which file supplies a value, read the `env` block of `<project>/.claude/settings.local.json`, `<project>/.claude/settings.json`, and `~/.claude/settings.json` (expand `~` to the absolute home path for Read) in that order; the first that sets the key wins. `jq -r .env.DOCS_VAULT <file>` shows one file's value.
