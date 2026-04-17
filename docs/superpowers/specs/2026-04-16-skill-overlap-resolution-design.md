# Skill Overlap Resolution — Design

> Source: GitHub issue [evans-sam/skills#6](https://github.com/evans-sam/skills/issues/6)
> Date: 2026-04-16

## Context

This plugin (`evans-sam/skills`) is commonly installed alongside the `superpowers` and `feature-dev` plugins. Eight skills here overlap conceptually with skills in those plugins, creating trigger ambiguity in Claude Code's system prompt: when two skills compete for the same trigger phrase, behavior becomes unpredictable across invocations.

Issue #6 lists seven overlap rows (eight skills, since `triage-issue` and `prd-to-issues` share a row). The issue proposes three per-skill options: **Remove**, **Rename + differentiate**, or **Keep** (rare). It also calls for coherence across the set — resolved in one pass, not skill-by-skill.

## Positioning decision

**This plugin is standalone-capable.** Each skill must still function when the plugin is installed alone (without superpowers/feature-dev). We therefore do NOT remove any of the eight skills. Fixes happen via description rewrites so that when both plugins are installed, triggers do not collide.

Superpowers skills, by contrast, often assume the full superpowers suite is present. That asymmetry is why we can't simply defer to superpowers for overlapping skills.

## Renaming decision

**No skill names change.** None of the eight local skill names is identical to its counterpart name (`tdd` vs `test-driven-development`, `write-a-plan` vs `writing-plans`, etc.). Descriptions carry the primary triggering weight. Renaming would break any users who invoke these skills by slash-command and is not needed to resolve the overlap.

## Per-skill resolution

All eight skills: **KEEP**, with a new description. No body changes, no file moves, no renames.

| Local skill | Counterpart | Differentiation angle |
|---|---|---|
| `tdd` | `superpowers:test-driven-development` | Vertical-slice tracer bullets + integration-style tests through public APIs + interface design up front |
| `write-a-plan` | `superpowers:writing-plans` | Phase-level output (not task-step level), built via user interview with no PRD required |
| `prd-to-plan` | `superpowers:writing-plans` | PRD-ingest (local/Notion/wiki) + external context (Linear/Figma/Notion MCPs) + phase-level output |
| `write-a-skill` | `superpowers:writing-skills`, `skill-creator:skill-creator`, `anthropic-skills:skill-creator` | Lightweight template scaffold — no eval loop, no TDD-for-skills workflow |
| `troubleshoot` | `superpowers:systematic-debugging` | Different job entirely: search connected tools (Slack/Notion/Linear/docs) for a prior solution to an operational issue (deploy/install/infra), not a code-logic debugging workflow |
| `grill-me` | `superpowers:brainstorming` | Stress-test an EXISTING plan or design — brainstorming explores new ideas from scratch |
| `triage-issue` | `feature-dev:feature-dev` | Produces a markdown bug-triage artifact with a TDD fix plan — not a live feature-build workflow |
| `prd-to-issues` | `feature-dev:feature-dev` | Produces independent ticket artifacts (GitHub/Linear/local/Notion) with HITL/AFK tags + dependency links — not a live feature-build workflow |

## New descriptions

Each description below replaces the existing `description:` field in the skill's SKILL.md YAML frontmatter. Skill body, name, and all other fields are unchanged.

### 1. `tdd`

> Plan a vertical-slice TDD sequence (tracer bullets): design interfaces, choose which behaviors to test through public APIs, then drive implementation one test at a time. Use when user mentions tracer bullets, vertical slice TDD, or wants integration-style test-first development with interface-design up front.

### 2. `write-a-plan`

> Build a phase-level implementation plan from a vague idea via user interview + codebase exploration. Output is numbered tracer-bullet phases (not task-by-task steps). Use when user has no spec/PRD yet and wants to think through how to build something, mentions "phased plan" or "tracer bullet phases," or wants to decompose an idea into vertical slices before getting to step-by-step detail.

### 3. `prd-to-plan`

> Turn an existing PRD (local file, Notion, GitHub wiki) into a phase-level implementation plan via tracer-bullet vertical slices, pulling context from Linear/Figma/Notion MCPs where provided. Use when user points to a PRD and wants to break it into phases — not task-by-task steps. Requires an existing PRD.

### 4. `write-a-skill`

> Quick-scaffold a new skill with frontmatter + SKILL.md template + optional bundled files. Use for lightweight skill creation when user doesn't want an eval-driven loop or a TDD-for-skills workflow — fast template-only approach.

### 5. `troubleshoot`

> Search connected tools (Slack, Notion, Linear, docs) for a prior solution to an OPERATIONAL issue — deploy failures, install errors, infra problems, environment breakage. Use when user pastes CLI error output from a non-code failure, asks to troubleshoot an ops issue, or mentions deploys, installs, or infra that's broken. Not for debugging code logic.

### 6. `grill-me`

> Stress-test an EXISTING plan, design, or spec by interviewing the user relentlessly — walking the decision tree branch-by-branch and resolving dependencies between decisions. Use when user has already drafted a plan and wants it grilled, says "grill me," or wants to pressure-test a design. Not for exploring a new idea from scratch.

### 7. `triage-issue`

> Triage a bug hands-off: explore the codebase to find root cause, then produce a markdown issue document with a TDD fix plan (ordered RED-GREEN cycles). Destination configurable — GitHub issue, local file, Linear, Notion. Use when user reports a bug and wants a triage artifact rather than a live fix workflow. Not for building new features.

### 8. `prd-to-issues`

> Turn a PRD into independent ticket artifacts — GitHub issues, Linear tickets, local files, or Notion pages — with HITL/AFK tags and dependency links. Each ticket is a tracer-bullet vertical slice. Use when user wants to produce standalone work items from a PRD. Not for a live feature-building workflow.

## Files touched

Exactly eight files, each an edit to a YAML frontmatter field:

- `skills/tdd/SKILL.md`
- `skills/write-a-plan/SKILL.md`
- `skills/prd-to-plan/SKILL.md`
- `skills/write-a-skill/SKILL.md`
- `skills/troubleshoot/SKILL.md`
- `skills/grill-me/SKILL.md`
- `skills/triage-issue/SKILL.md`
- `skills/prd-to-issues/SKILL.md`

## Out of scope

Per issue #6:

- `plugin.json` and `marketplace.json` — untouched
- All non-overlapping skills: `blueprint-draft`, `blueprint-publish`, `blueprint-scratchpad`, `design-an-interface`, `improve-codebase-architecture`, `ubiquitous-language`, `request-refactor-plan`, `setup-pre-commit`, `git-guardrails-claude-code`, `write-a-prd`, `write-a-test-plan`
- Skill body content (only the `description:` field changes)
- Skill names (no renames)

## Acceptance criteria

- [ ] All eight SKILL.md files have their `description:` field replaced with the corresponding draft from this spec
- [ ] Each description parses as valid YAML and stays under 1024 characters
- [ ] Skill `name:` fields are unchanged on all eight files
- [ ] `plugin.json` and `marketplace.json` are unchanged
- [ ] No non-overlapping skill files are modified
- [ ] All changes land in a single PR referencing issue #6

## Verification

Manual check after implementation:

```bash
for skill in tdd write-a-plan prd-to-plan write-a-skill troubleshoot grill-me triage-issue prd-to-issues; do
  echo "=== $skill ==="
  head -5 "skills/$skill/SKILL.md"
done
```

Confirm each prints the new description from this spec.
