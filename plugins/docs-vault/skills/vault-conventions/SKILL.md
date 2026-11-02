---
name: vault-conventions
description: This skill should be used when Claude is about to write or save durable documentation (a plan, spec or design doc, PRD, RFC, test plan, triage or root-cause write-up, glossary, blueprint, or MOC note), including when a producing skill (write-a-plan, writing-plans, brainstorming, write-a-prd, write-a-test-plan, triage-issue, ubiquitous-language) reaches its save step or names a default path such as docs/superpowers/plans/, ./plans/, specs/, or UBIQUITOUS_LANGUAGE.md; when a skill asks where to save; when the user says "put it in the vault", "write up the plan", "write the design doc", "write a test plan", or "write up the triage"; when the docs-vault guard hook denies a write; or when the vault has no AGENTS.md. Covers the vault workflow, layout, and which folder each skill writes to. Not for READMEs, CHANGELOGs, code comments, or test files.
---

# Docs vault conventions

Durable documentation lives in one vault outside every code repo. The vault's own `AGENTS.md` is the authority on naming, frontmatter, linking, and MOC notes. This skill gives the workflow around it and the fallback for a vault that has no `AGENTS.md` yet.

## Resolve the vault

The session-start context names the vault path. When that context is absent, or to check `DOCS_VAULT_GUARD` and `DOCS_VAULT_EXTRA_PATTERNS`, run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/resolve-vault.sh"
```

It merges the `env` blocks of `.claude/settings.local.json`, `.claude/settings.json`, and `~/.claude/settings.json` in that order and falls back to the process environment. An empty `DOCS_VAULT` means the plugin isn't configured: tell the user to run `/docs-vault:setup <path>`, keep the doc body in the reply until the vault exists, and write nothing into the repo.

## Before writing a doc

1. Read `$DOCS_VAULT/AGENTS.md`. When the vault has none, read the bundled copy instead and suggest `/docs-vault:setup` so the vault gets its own:

   ```bash
   cat "${CLAUDE_PLUGIN_ROOT}/templates/AGENTS.md"
   ```

2. Pick the folder by type (table below).
3. Build the filename from the date, issue key, slug, and type suffix as the Naming section of AGENTS.md specifies.
4. Write the frontmatter AGENTS.md specifies: `title`, `type`, `status`, `project`, `issue`, `parent`, the tracker URL, `created`, `tags`.
5. Link the doc into the hierarchy: set `parent`, add a `Part of [[<moc>]]` line, and update that MOC in `maps/` to link the new doc. Create the MOC first when it doesn't exist, following the MOC section of AGENTS.md.

Never commit the doc into a code repo, never leave it at a skill's default path, and never ask which directory to use: the vault is the answer. When a skill would open a tracker issue for the doc body, let the issue exist as the tracker entry and put the body in the vault with the issue linking to it.

## Layout

One flat folder per type. The work hierarchy (program → project → issue → sub-issue) is expressed through linked MOC notes in `maps/`, never through nested folders.

| Folder | Holds |
|---|---|
| `prds/` | product requirements |
| `specs/` | designs, architecture, brainstorm output, blueprints |
| `plans/` | implementation plans and refactor RFCs |
| `test-plans/` | QA and test plans |
| `triage/` | bug investigations, root-cause write-ups |
| `reference/` | glossaries, runbooks, durable cross-project knowledge |
| `maps/` | MOC notes, one per node of the work hierarchy |
| `scratch/` | WIP shaping not yet tied to an issue |

Pick the closest existing folder. Add a top-level folder only for a new broad category, never for a tool or a single feature.

## Where each skill writes

| Skill | Folder | `type` |
|---|---|---|
| write-a-prd | `prds/` | prd |
| brainstorming, design-an-interface | `specs/` | spec |
| blueprint-draft, blueprint-publish | `specs/` + project MOC in `maps/` | blueprint |
| write-a-plan, writing-plans, prd-to-plan | `plans/` | plan |
| request-refactor-plan, improve-codebase-architecture | `plans/` | rfc |
| write-a-test-plan | `test-plans/` | test-plan |
| triage-issue | `triage/` | triage |
| ubiquitous-language | `reference/` as `<project>-glossary.md` | glossary |
| blueprint-scratchpad | `scratch/` | scratch |
| prd-to-issues | tracker issues, plus one issue MOC in `maps/` per issue | moc |

A skill not listed writes to the folder whose type matches its output.

## When the guard denies a write

Outside the vault, the PreToolUse hook denies any write under `docs/superpowers/`, any `UBIQUITOUS_LANGUAGE.md`, any `.md` with a `plans/`, `specs/`, or `test-plans/` path segment, and any path matching a `DOCS_VAULT_EXTRA_PATTERNS` glob. Keep the content and change the destination: pick the folder, rename the file, add the frontmatter, link the MOC, and re-issue the write. If the denied path is a repo file the user wants kept there (a repo whose own `plans/` folder is intentional), say so and offer `/docs-vault:setup --guard off --project`. Don't turn the guard off unless the user asks.
