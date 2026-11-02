# AGENTS.md — Docs Vault

This is an Obsidian vault for durable engineering documentation: PRDs, specs, plans, test plans, triage write-ups, RFCs, glossaries, blueprints. Anything a skill or workflow generates that should outlive a session lands here, whatever repo or tool produced it. These docs are never committed into a code repo (the vault is synced by Obsidian or whatever syncs this folder, not by a code repo's git).

When a skill's default would write into a code repo, open a GitHub/Linear issue for the doc body, or ask which directory to use, route the file here instead and follow the conventions below.

## Two axes

Docs sit on two axes at once, and keeping them separate is what makes the vault work:

- **Type** = the folder a file lives in (`plans/`, `specs/`, …). One flat folder per type. This is what skills map onto directly.
- **Work hierarchy** = program → project → issue → sub-issue, expressed as linked **MOC notes** in `maps/`, not as nested folders. A doc joins the hierarchy by linking its MOC, never by moving folders.

Browse by type through folders. Browse by initiative through MOCs and the graph view. A doc that touches two projects links both MOCs without being copied.

## Layout

```
<vault>/
├── prds/         product requirements
├── specs/        designs, architecture, brainstorm output, blueprints
├── plans/        implementation plans + refactor RFCs
├── test-plans/   QA / test plans
├── triage/       bug investigations, root-cause write-ups
├── reference/    glossaries, durable cross-project knowledge, runbooks
├── maps/         MOC notes — the work hierarchy, nested through links
└── scratch/      WIP shaping / brainstorm not yet tied to an issue
```

Pick the closest existing folder. Add a new top-level folder only for a genuinely new broad category, never for a tool and never for a single feature. There is no per-tool folder.

## Naming

- Issue-scoped doc: `YYYY-MM-DD-<issue-key>-<slug>-<type>.md`
  e.g. `2026-06-09-elg-2238-dependent-demographics-design.md`
- Unscoped doc: `YYYY-MM-DD-<slug>-<type>.md`
- MOC note: the lowercased issue key or project slug, no date
  e.g. `elg-2238.md`, `eligibility-renaissance-phase-2a.md`

Living docs carry no date: glossaries in `reference/` as `<project>-glossary.md`, MOC notes in `maps/` as above.

Keep the `<type>` suffix the producing skill already uses: `-prd`, `-design`, `-plan`, `-rfc`, `-test-plan`, `-triage`, `-blueprint`, `-glossary`. `-design` files take `type: spec`. The issue key inside the filename (Linear, Jira, GitHub, whichever tracker is in use) keeps every wikilink target unique across the vault, so `[[...]]` links never collide.

## Frontmatter (every doc)

```yaml
---
title: pVerify adapter, dependent demographics
type: prd | spec | plan | test-plan | triage | rfc | glossary | blueprint | moc | scratch
status: draft | active | done | superseded
project: eligibility-renaissance-phase-2a   # MOC slug; omit if none
issue: ELG-2238                             # issue key; omit if none
parent: "[[eligibility-renaissance-phase-2a]]"   # the MOC one level up
linear: https://linear.app/<workspace>/issue/ELG-2238/...   # Linear or other tracker URL; omit if none
created: 2026-06-09
tags: [eligibility, pverify]
---
```

`type` and `status` are what give you a type-view and a status-view without type-nested folders. Query them with search or Dataview.

Omit `parent` only for a doc not yet tied to any project or issue (typically in `scratch/`), and add it as soon as the work is scoped.

## Linking

The reason this is a vault and not a folder of files: every doc connects to its neighbours. No orphans.

- **Up** — set `parent:` and add an inline `Part of [[<moc>]]` line. A leaf doc points at its issue or project MOC.
- **Across** — link the sibling docs of the same issue: design ↔ plan ↔ test-plan.
- **Down** — every MOC links to its own docs and to its child MOCs, and back up to its parent MOC.
- **External** — tracker issue, Notion PRD/blueprint, Slack thread, Figma board go as plain URLs under a `## References` heading. Mirror what the tracker's project description already lists.
- When you create a doc tied to an issue or project, **update that node's MOC to link it** — and create the MOC first if it doesn't exist yet.

## MOC notes and the hierarchy

A MOC (map of content) is the index note for one node of the work hierarchy. Nodes nest through links, to any depth:

```
maps/eligibility-renaissance.md            program  → links each phase MOC
maps/eligibility-renaissance-phase-2a.md   project  → blueprint summary + links every issue MOC
maps/elg-2238.md                           issue    → links its design/plan/test-plan + any sub-issue MOCs
maps/elg-2238-<sub>.md                     sub-issue
```

A project MOC body doubles as the local mirror of the project's blueprint or brief: hypothesis, scope, links to the PRD and specs, and a checklist of child issues with status. Sub-projects are child MOCs under a program MOC. Add a level whenever the work splits; nothing on disk has to move.

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
| ubiquitous-language | `reference/` (`<project>-glossary.md`, not `UBIQUITOUS_LANGUAGE.md`) | glossary |
| blueprint-scratchpad | `scratch/` | scratch |
| prd-to-issues | creates tracker issues; add one issue MOC in `maps/` per issue | moc |

A skill not in this table writes to the folder whose type matches its output. If a skill defaults to `./plans/`, `docs/superpowers/...`, any repo path, or asks where to save, override it to the matching folder above. If a skill would commit to a code repo, don't — the file belongs here. If a skill opens a tracker issue, let it (that's the tracker); the doc body still lives here and the issue links to it.
