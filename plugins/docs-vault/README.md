# docs-vault

Keeps generated documentation out of code repos and in one docs vault (an Obsidian vault, or any folder of markdown). Plans, specs, PRDs, RFCs, test plans, triage write-ups, glossaries, and blueprints land there whatever skill produced them.

Three parts:

- A SessionStart hook that gives Claude the rule and the vault path at the start of every session, resumed ones included, and again after `/clear` or a compaction.
- A PreToolUse hook that denies a Write, Edit, or MultiEdit to the paths skills default to (`plans/`, `specs/`, `test-plans/`, `docs/superpowers/`, `UBIQUITOUS_LANGUAGE.md`) when the path is outside the vault. The denial reason tells Claude where to write instead.
- `/docs-vault:setup`, which records the vault path in a Claude Code settings file and scaffolds the vault's folders and `AGENTS.md`.

The `vault-conventions` skill carries the layout, naming, frontmatter, and MOC linking rules for a vault that has no `AGENTS.md` yet.

## Install

```
/plugin marketplace add evans-sam/skills
/plugin install docs-vault@evans-sam-skills
```

Then, in any session:

```
/docs-vault:setup ~/docs
```

Needs bash and jq on PATH. Without jq both hooks exit silently and nothing is enforced.

## Configuration

Settings are environment variables in the `env` block of a Claude Code settings file. The hooks and the setup skill read those files directly on every call, in Claude Code's own order: `.claude/settings.local.json`, then `.claude/settings.json`, then `~/.claude/settings.json`; the first file that sets a key wins. A variable exported in the shell is used only when no settings file sets it. A settings change applies from the next tool call; the session-start context is built once per session and reflects a change after the next start, `/clear`, or compaction.

`DOCS_VAULT` is the absolute path of the vault. Unset, the plugin stays inactive apart from a one-line reminder at session start.

`DOCS_VAULT_GUARD` set to `off` disables the write guard at that scope. The session rule still applies.

`DOCS_VAULT_EXTRA_PATTERNS` is a colon-separated list of shell globs matched against the full path, for example `*/adr/*.md:*/rfcs/*`. A match is denied like the built-in patterns.

User level, `~/.claude/settings.json`:

```json
{
  "env": {
    "DOCS_VAULT": "/Users/you/docs"
  }
}
```

Per-project override for a repo whose own `plans/` folder is intentional, in that repo's `.claude/settings.json`:

```json
{
  "env": {
    "DOCS_VAULT_GUARD": "off"
  }
}
```

`/docs-vault:setup --guard off --project` writes that for you.

## What the guard blocks

A Write, Edit, or MultiEdit whose path is outside `DOCS_VAULT` and is one of:

- a file named `UBIQUITOUS_LANGUAGE.md`
- any path containing `/docs/superpowers/`
- a `.md` file with a `/plans/`, `/specs/`, or `/test-plans/` segment
- anything matching a glob in `DOCS_VAULT_EXTRA_PATTERNS`

Everything else passes: READMEs, `docs/guide/`, code, non-markdown files under `plans/`.

## Vault layout

`/docs-vault:setup` creates these folders and copies `templates/AGENTS.md` into the vault when it has none:

```
<vault>/
├── prds/         product requirements
├── specs/        designs, architecture, brainstorm output, blueprints
├── plans/        implementation plans + refactor RFCs
├── test-plans/   QA / test plans
├── triage/       bug investigations, root-cause write-ups
├── reference/    glossaries, durable cross-project knowledge, runbooks
├── maps/         MOC notes, the work hierarchy expressed through links
└── scratch/      WIP shaping not yet tied to an issue
```

Setup never overwrites an existing `AGENTS.md`, so edit the vault's copy to make the conventions your own.

## Migrating from a standalone hook

If the same guard was installed by hand before this plugin existed:

1. Remove the `Write|Edit|MultiEdit` hook entry that points at `~/.claude/hooks/vault-doc-guard.sh` from `~/.claude/settings.json`, and delete the script.
2. Delete the "Documentation Output" section from `~/.claude/CLAUDE.md`; the SessionStart hook now supplies it.
3. Run `/docs-vault:setup <same vault path>`. The existing `AGENTS.md` is kept.

## Development

```
bash plugins/docs-vault/tests/run.sh
```

The tests run the hooks and setup scripts against a temporary HOME, project, and vault and cover settings precedence, every guard pattern, the guard-off and extra-pattern settings, the session-start output in both states, settings-file preservation, and the scaffold's never-overwrite rule.

Hook changes need a new Claude Code session to load. Run `claude --debug` to see the hooks fire.
