# Skill Overlap Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the `description:` YAML frontmatter field in eight SKILL.md files to resolve trigger-phrase collisions with the superpowers and feature-dev plugins, per [issue #6](https://github.com/evans-sam/skills/issues/6).

**Architecture:** Single coherent change across eight skills. Each task edits one SKILL.md's frontmatter — name and body untouched. One commit bundles all eight edits. Final task opens a PR referencing the issue. Spec at [docs/superpowers/specs/2026-04-16-skill-overlap-resolution-design.md](../specs/2026-04-16-skill-overlap-resolution-design.md).

**Tech Stack:** Markdown files with YAML frontmatter. No code, no tests to write — verification is `grep` against the updated files.

---

## Notes on testing approach

This plan modifies documentation (YAML frontmatter), not code. There are no unit tests to write. Per-task verification uses `grep` to confirm the new description is present in the file. The "failing test" step in TDD translates here to confirming the OLD description is present *before* the edit and the NEW description is present *after*.

Batch-commit at the end (one commit for all eight edits) — the change is a single coherent unit tied to one issue, so fragmented commits would obscure the intent.

---

## Task 1: Update `tdd` description

**Files:**
- Modify: `skills/tdd/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Test-driven development with red-green-refactor loop' skills/tdd/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/tdd/SKILL.md`.

`old_string`:
```
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.
```

`new_string`:
```
description: "Plan a vertical-slice TDD sequence (tracer bullets): design interfaces, choose which behaviors to test through public APIs, then drive implementation one test at a time. Use when user mentions tracer bullets, vertical slice TDD, or wants integration-style test-first development with interface-design up front."
```

Note: wrap the new value in double quotes because it contains a colon after "(tracer bullets)" — bare YAML scalars would interpret that as a mapping.

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Plan a vertical-slice TDD sequence' skills/tdd/SKILL.md
```

Expected: `1`

---

## Task 2: Update `write-a-plan` description

**Files:**
- Modify: `skills/write-a-plan/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Create a robust implementation plan from scratch' skills/write-a-plan/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/write-a-plan/SKILL.md`.

`old_string`:
```
description: Create a robust implementation plan from scratch through relentless interviewing, codebase exploration, and vertical slicing. Use when user wants to write a plan, create an implementation plan, plan a feature, or needs to think through how to build something — without requiring a PRD first.
```

`new_string`:
```
description: Build a phase-level implementation plan from a vague idea via user interview + codebase exploration. Output is numbered tracer-bullet phases (not task-by-task steps). Use when user has no spec/PRD yet and wants to think through how to build something, mentions "phased plan" or "tracer bullet phases," or wants to decompose an idea into vertical slices before getting to step-by-step detail.
```

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Build a phase-level implementation plan from a vague idea' skills/write-a-plan/SKILL.md
```

Expected: `1`

---

## Task 3: Update `prd-to-plan` description

**Files:**
- Modify: `skills/prd-to-plan/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Turn a PRD into a multi-phase implementation plan' skills/prd-to-plan/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/prd-to-plan/SKILL.md`.

`old_string`:
```
description: Turn a PRD into a multi-phase implementation plan using tracer-bullet vertical slices. Use when user wants to break down a PRD, create an implementation plan, plan phases from a PRD, or mentions "tracer bullets".
```

`new_string`:
```
description: Turn an existing PRD (local file, Notion, GitHub wiki) into a phase-level implementation plan via tracer-bullet vertical slices, pulling context from Linear/Figma/Notion MCPs where provided. Use when user points to a PRD and wants to break it into phases — not task-by-task steps. Requires an existing PRD.
```

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Turn an existing PRD (local file, Notion, GitHub wiki)' skills/prd-to-plan/SKILL.md
```

Expected: `1`

---

## Task 4: Update `write-a-skill` description

**Files:**
- Modify: `skills/write-a-skill/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Create new agent skills with proper structure' skills/write-a-skill/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/write-a-skill/SKILL.md`.

`old_string`:
```
description: Create new agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, or build a new skill.
```

`new_string`:
```
description: Quick-scaffold a new skill with frontmatter + SKILL.md template + optional bundled files. Use for lightweight skill creation when user doesn't want an eval-driven loop or a TDD-for-skills workflow — fast template-only approach.
```

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Quick-scaffold a new skill' skills/write-a-skill/SKILL.md
```

Expected: `1`

---

## Task 5: Update `troubleshoot` description

**Files:**
- Modify: `skills/troubleshoot/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Research and resolve operational issues' skills/troubleshoot/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/troubleshoot/SKILL.md`.

`old_string`:
```
description: Research and resolve operational issues (deploy failures, install errors, infra problems) by searching Slack, Notion, Linear, docs, and other connected sources for prior solutions. Use when user says "troubleshoot", "help me fix", "this is broken", pastes CLI error output, or needs help diagnosing a non-code issue like a failed deployment or environment problem.
```

`new_string`:
```
description: Search connected tools (Slack, Notion, Linear, docs) for a prior solution to an OPERATIONAL issue — deploy failures, install errors, infra problems, environment breakage. Use when user pastes CLI error output from a non-code failure, asks to troubleshoot an ops issue, or mentions deploys, installs, or infra that's broken. Not for debugging code logic.
```

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Search connected tools (Slack, Notion, Linear, docs)' skills/troubleshoot/SKILL.md
```

Expected: `1`

---

## Task 6: Update `grill-me` description

**Files:**
- Modify: `skills/grill-me/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Interview the user relentlessly about a plan or design' skills/grill-me/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/grill-me/SKILL.md`.

`old_string`:
```
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
```

`new_string`:
```
description: Stress-test an EXISTING plan, design, or spec by interviewing the user relentlessly — walking the decision tree branch-by-branch and resolving dependencies between decisions. Use when user has already drafted a plan and wants it grilled, says "grill me," or wants to pressure-test a design. Not for exploring a new idea from scratch.
```

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Stress-test an EXISTING plan' skills/grill-me/SKILL.md
```

Expected: `1`

---

## Task 7: Update `triage-issue` description

**Files:**
- Modify: `skills/triage-issue/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Triage a bug or issue by exploring the codebase' skills/triage-issue/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/triage-issue/SKILL.md`.

`old_string`:
```
description: Triage a bug or issue by exploring the codebase to find root cause, then create a markdown issue document with a TDD-based fix plan. Use when user reports a bug, wants to file an issue, mentions "triage", or wants to investigate and plan a fix for a problem.
```

`new_string`:
```
description: "Triage a bug hands-off: explore the codebase to find root cause, then produce a markdown issue document with a TDD fix plan (ordered RED-GREEN cycles). Destination configurable — GitHub issue, local file, Linear, Notion. Use when user reports a bug and wants a triage artifact rather than a live fix workflow. Not for building new features."
```

Note: wrap in double quotes because the value contains a colon after "hands-off".

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Triage a bug hands-off' skills/triage-issue/SKILL.md
```

Expected: `1`

---

## Task 8: Update `prd-to-issues` description

**Files:**
- Modify: `skills/prd-to-issues/SKILL.md` (line 3, the `description:` frontmatter field)

- [ ] **Step 1: Confirm current description is present**

Run:
```bash
grep -c 'Break a PRD into independently-grabbable implementation issues' skills/prd-to-issues/SKILL.md
```

Expected: `1`

- [ ] **Step 2: Replace the description field**

Use the Edit tool on `skills/prd-to-issues/SKILL.md`.

`old_string`:
```
description: Break a PRD into independently-grabbable implementation issues using tracer-bullet vertical slices. Use when user wants to convert a PRD to issues, create implementation tickets, or break down a PRD into work items.
```

`new_string`:
```
description: Turn a PRD into independent ticket artifacts — GitHub issues, Linear tickets, local files, or Notion pages — with HITL/AFK tags and dependency links. Each ticket is a tracer-bullet vertical slice. Use when user wants to produce standalone work items from a PRD. Not for a live feature-building workflow.
```

- [ ] **Step 3: Verify new description is present**

Run:
```bash
grep -c 'Turn a PRD into independent ticket artifacts' skills/prd-to-issues/SKILL.md
```

Expected: `1`

---

## Task 9: Final verification — all 8 descriptions updated, nothing else changed

**Files:**
- Read-only verification across all eight SKILL.md files

- [ ] **Step 1: Confirm all 8 new descriptions are present**

Run:
```bash
for pair in \
  "tdd:Plan a vertical-slice TDD sequence" \
  "write-a-plan:Build a phase-level implementation plan from a vague idea" \
  "prd-to-plan:Turn an existing PRD (local file, Notion, GitHub wiki)" \
  "write-a-skill:Quick-scaffold a new skill" \
  "troubleshoot:Search connected tools (Slack, Notion, Linear, docs)" \
  "grill-me:Stress-test an EXISTING plan" \
  "triage-issue:Triage a bug hands-off" \
  "prd-to-issues:Turn a PRD into independent ticket artifacts" \
; do
  skill="${pair%%:*}"
  needle="${pair#*:}"
  count=$(grep -c "$needle" "skills/$skill/SKILL.md" 2>/dev/null || echo 0)
  printf '%-20s %s\n' "$skill" "$count"
done
```

Expected: each skill prints `1`.

- [ ] **Step 2: Confirm old descriptions are GONE**

Run:
```bash
for pair in \
  "tdd:red-green-refactor loop" \
  "write-a-plan:Create a robust implementation plan from scratch" \
  "prd-to-plan:Turn a PRD into a multi-phase implementation plan" \
  "write-a-skill:Create new agent skills with proper structure" \
  "troubleshoot:Research and resolve operational issues" \
  "grill-me:Interview the user relentlessly about a plan or design" \
  "triage-issue:Triage a bug or issue by exploring the codebase" \
  "prd-to-issues:Break a PRD into independently-grabbable" \
; do
  skill="${pair%%:*}"
  needle="${pair#*:}"
  count=$(grep -c "$needle" "skills/$skill/SKILL.md" 2>/dev/null || echo 0)
  printf '%-20s %s\n' "$skill" "$count"
done
```

Expected: each skill prints `0`.

- [ ] **Step 3: Confirm no other files changed**

Run:
```bash
git status --short
```

Expected: output lists only the eight `skills/<name>/SKILL.md` files as modified, plus any plan/spec file if this is the same branch. `plugin.json` and `marketplace.json` must NOT appear.

- [ ] **Step 4: Confirm skill names untouched**

Run:
```bash
for skill in tdd write-a-plan prd-to-plan write-a-skill troubleshoot grill-me triage-issue prd-to-issues; do
  name=$(grep '^name:' "skills/$skill/SKILL.md" | head -1)
  printf '%-20s %s\n' "$skill" "$name"
done
```

Expected: each line prints `name: <skill>` matching the directory name exactly. No renames.

- [ ] **Step 5: Confirm each new description is under 1024 chars**

Run:
```bash
for skill in tdd write-a-plan prd-to-plan write-a-skill troubleshoot grill-me triage-issue prd-to-issues; do
  len=$(awk '/^description:/{sub(/^description: ?/,""); print length($0); exit}' "skills/$skill/SKILL.md")
  printf '%-20s %s\n' "$skill" "$len"
done
```

Expected: each length under 1024. (All drafts are well under 500 chars, so this is a safety check.)

---

## Task 10: Commit all eight edits

**Files:** None (git operation only)

- [ ] **Step 1: Stage the eight SKILL.md files**

Run:
```bash
git add \
  skills/tdd/SKILL.md \
  skills/write-a-plan/SKILL.md \
  skills/prd-to-plan/SKILL.md \
  skills/write-a-skill/SKILL.md \
  skills/troubleshoot/SKILL.md \
  skills/grill-me/SKILL.md \
  skills/triage-issue/SKILL.md \
  skills/prd-to-issues/SKILL.md
```

- [ ] **Step 2: Review staged diff**

Run:
```bash
git diff --cached --stat
```

Expected: eight files changed, each with a small line delta (one-line replacement per file).

- [ ] **Step 3: Create the commit**

Run:
```bash
git commit -m "$(cat <<'EOF'
skills: differentiate descriptions to resolve overlap with superpowers + feature-dev

Rewrites the description field on 8 SKILL.md files so their trigger
phrases no longer collide with superpowers and feature-dev plugin
skills when installed side-by-side. Skill names and bodies are
untouched; plugin.json and marketplace.json are not modified.

Resolves #6.
EOF
)"
```

Expected: commit succeeds; pre-commit hooks (if any) pass.

- [ ] **Step 4: Confirm commit landed**

Run:
```bash
git log -1 --stat
```

Expected: top commit shows the 8 SKILL.md files.

---

## Task 11: Open PR

**Files:** None (GitHub operation only)

- [ ] **Step 1: Push the branch to origin**

Run:
```bash
git push -u origin HEAD
```

Expected: branch pushed; GitHub prints a compare URL.

- [ ] **Step 2: Open the PR**

Run:
```bash
gh pr create --title "skills: resolve description overlap with superpowers + feature-dev (#6)" --body "$(cat <<'EOF'
## Summary

- Rewrites the `description:` field on 8 SKILL.md files so that trigger phrases no longer collide with `superpowers` and `feature-dev` skills when those plugins are installed alongside this one.
- All 8 skills kept (this plugin stays standalone-capable). No renames. Bodies unchanged. `plugin.json` and `marketplace.json` unchanged.
- Per-skill rationale and exact description text: see [docs/superpowers/specs/2026-04-16-skill-overlap-resolution-design.md](docs/superpowers/specs/2026-04-16-skill-overlap-resolution-design.md).

Resolves #6.

## Test plan

- [ ] Spot-check each of the 8 SKILL.md files: new description is present, old is gone, `name:` field unchanged
- [ ] Confirm `plugin.json` and `marketplace.json` are unchanged
- [ ] Confirm no non-overlapping skill files are modified
EOF
)"
```

Expected: `gh` prints the PR URL.

- [ ] **Step 3: Report PR URL**

Print the URL returned by `gh pr create` so the user can click through.

---

## Self-Review (completed inline after writing)

**Spec coverage:** every section of the spec (positioning, renaming, per-skill resolution, new descriptions, files touched, out of scope, acceptance criteria, verification) is reflected in the plan's tasks. Each of the 8 acceptance criteria maps to a verification step in Task 9.

**Placeholder scan:** no TBD/TODO. Every `old_string` and `new_string` is literal. Every command is a complete shell invocation with expected output. No "add error handling" hand-waving.

**Type consistency:** skill names used in later tasks (Task 9 verification loop, Task 10 git-add) match the skill names in Tasks 1-8 exactly. Description text in verification greps (Task 9) matches the `new_string` in Tasks 1-8 exactly (checked pair-by-pair).
