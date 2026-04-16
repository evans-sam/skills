# Fix Claude Code Plugin Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `evans-sam/skills` repo installable as a Claude Code plugin via the standard two-command flow (`/plugin marketplace add` then `/plugin install`), and remove hardcoded output paths in 4 skills that only work on the author's laptop.

**Architecture:** Self-hosted single-plugin marketplace — the repo root holds BOTH a `.claude-plugin/marketplace.json` (declaring the marketplace `evans-sam-skills`) AND a `.claude-plugin/plugin.json` (declaring the single plugin `skills` with `source: "./"`). Skills that hardcoded `~/Development/docs/` or `./plans/` in their opening prose get the stale sentence removed — their bodies already have proper "ask the user where to save" sections from an earlier merged migration (#1 `Implement flexible document storage options for skills`).

**Tech Stack:** Claude Code plugin system (JSON manifests in `.claude-plugin/`), Markdown skills.

**Reference for marketplace.json schema:** `/Users/evansst/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json` (the official Anthropic marketplace — mirrors the structure we're building).

**Reference for "ask the user" pattern:** [skills/write-a-prd/SKILL.md](skills/write-a-prd/SKILL.md) — already uses the pattern we'll align the four broken skills to (actually we just strip the stale path assertion since the relevant skill bodies already have the pattern).

---

### Task 1: Create marketplace.json and update plugin.json

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Modify: `.claude-plugin/plugin.json`

**Why together:** Both files reference the plugin name `skills`. Splitting them across two commits would leave the repo in an inconsistent state mid-commit (marketplace declares plugin `skills` but plugin.json still says `evans-sam-skills`, or vice versa). One atomic change.

- [ ] **Step 1: Write `.claude-plugin/marketplace.json` with this exact content:**

```json
{
  "name": "evans-sam-skills",
  "description": "A collection of agent skills for planning, development, and tooling",
  "owner": { "name": "Sam Evans" },
  "plugins": [
    {
      "name": "skills",
      "source": "./",
      "description": "A collection of agent skills for planning, development, and tooling"
    }
  ]
}
```

- [ ] **Step 2: Validate marketplace.json parses as JSON**

```bash
jq . .claude-plugin/marketplace.json
```

Expected: the JSON prints back, no error. If `jq` reports a parse error, fix the file before proceeding.

- [ ] **Step 3: Edit `.claude-plugin/plugin.json`**

Read the current file first:

```bash
cat .claude-plugin/plugin.json
```

Current content (exact):

```json
{
  "name": "evans-sam-skills",
  "version": "1.0.0",
  "description": "A collection of agent skills for planning, development, and tooling",
  "author": { "name": "Sam Evans" },
  "license": "MIT"
}
```

Replace the entire file with:

```json
{
  "name": "skills",
  "version": "1.0.0",
  "description": "A collection of agent skills for planning, development, and tooling",
  "author": { "name": "Sam Evans" },
  "homepage": "https://github.com/evans-sam/skills",
  "repository": "https://github.com/evans-sam/skills",
  "license": "MIT",
  "keywords": ["skills", "planning", "tdd", "refactoring"]
}
```

Changes: `name` → `"skills"`; added `homepage`, `repository`, `keywords`.

- [ ] **Step 4: Validate plugin.json parses**

```bash
jq . .claude-plugin/plugin.json
```

Expected: JSON prints back, no error.

- [ ] **Step 5: Confirm both files agree on the plugin name**

```bash
jq -r .name .claude-plugin/plugin.json
jq -r '.plugins[0].name' .claude-plugin/marketplace.json
```

Expected: both commands print `skills`. If they differ, fix before committing.

- [ ] **Step 6: Stage and commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "$(cat <<'EOF'
chore(plugin): rename plugin to 'skills' and add marketplace manifest

Adds .claude-plugin/marketplace.json so the repo can be installed via
/plugin marketplace add evans-sam/skills + /plugin install skills@evans-sam-skills.

Renames the plugin from 'evans-sam-skills' to 'skills' so installed skills
appear as skills:<name> instead of the redundant evans-sam-skills:<name>.
Adds homepage, repository, keywords for discoverability.
EOF
)"
```

- [ ] **Step 7: Verify commit landed and working tree is clean**

```bash
git log -1 --stat
git status
```

Expected: latest commit touches exactly the two files above; `git status` shows "nothing to commit, working tree clean".

---

### Task 2: Rewrite README install section

**Files:**
- Modify: `README.md` (lines 1–19)

The current install section uses `claude plugin add` and a non-existent `--skill` flag, neither of which are real Claude Code commands. Replace with the correct two-command flow.

- [ ] **Step 1: Read the current README.md to confirm the section is exactly as below**

```bash
head -20 README.md
```

Expected first 20 lines (exact):

```markdown
# Agent Skills

A collection of agent skills that extend capabilities across planning, development, and tooling.

## Installation

Install as a Claude plugin:

```bash
claude plugin add evans-sam/skills
```

Or install individual skills after adding the plugin:

```bash
claude plugin add evans-sam/skills --skill write-a-plan --skill tdd
```

Skills are available immediately in Claude Code after installation.
```

If the text differs, STOP and read the whole file — someone has edited it since the plan was written.

- [ ] **Step 2: Replace the install section**

Use the Edit tool. `old_string`:

```markdown
## Installation

Install as a Claude plugin:

```bash
claude plugin add evans-sam/skills
```

Or install individual skills after adding the plugin:

```bash
claude plugin add evans-sam/skills --skill write-a-plan --skill tdd
```

Skills are available immediately in Claude Code after installation.
```

`new_string`:

```markdown
## Installation

Install as a Claude Code plugin:

```
/plugin marketplace add evans-sam/skills
/plugin install skills@evans-sam-skills
```

Skills are available immediately as `skills:<skill-name>` after installation.
```

Changes: uses the real `/plugin marketplace add` + `/plugin install` commands; drops the fictional `--skill` flag paragraph entirely; clarifies the post-install skill naming.

- [ ] **Step 3: Verify the fake install syntax is gone**

```bash
grep -nF 'claude plugin add' README.md
grep -nF '--skill' README.md
```

Expected: both commands exit with no output (ripgrep/grep "no match" exit code 1 is OK).

- [ ] **Step 4: Verify the new syntax is present**

```bash
grep -nF '/plugin marketplace add evans-sam/skills' README.md
grep -nF '/plugin install skills@evans-sam-skills' README.md
```

Expected: each command prints exactly one matching line.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: fix README install instructions to use /plugin marketplace add"
```

- [ ] **Step 6: Verify commit and tree state**

```bash
git log -1 --stat
git status
```

Expected: latest commit touches only README.md; working tree clean.

---

### Task 3: Remove hardcoded output paths in 4 skills

**Files:**
- Modify: `skills/improve-codebase-architecture/SKILL.md:8`
- Modify: `skills/write-a-test-plan/SKILL.md:8`
- Modify: `skills/write-a-plan/SKILL.md:3`
- Modify: `skills/prd-to-plan/SKILL.md:3,8`

**Why one task/commit:** All four edits are the same kind of change — remove a stale path assertion. The skill bodies already have proper "ask the user where to save" sections (e.g., `improve-codebase-architecture/SKILL.md:76`, `write-a-test-plan/SKILL.md:64`, `write-a-plan/SKILL.md:76`, `prd-to-plan/SKILL.md:72`), so we're just deleting the contradictory opening sentence rather than adding new behavior.

- [ ] **Step 1: Edit `skills/improve-codebase-architecture/SKILL.md` line 8**

`old_string`:

```
Explore a codebase like an AI would, surface architectural friction, discover opportunities for improving testability, and propose module-deepening refactors as markdown doc RFCs in `~/Development/docs/rfc`.
```

`new_string`:

```
Explore a codebase like an AI would, surface architectural friction, discover opportunities for improving testability, and propose module-deepening refactors as markdown doc RFCs.
```

Rationale: line 76 in the same file already has `Ask the user where they'd like to save this RFC. Common destinations: ...` — the stale line 8 assertion contradicts that. Just drop the path clause.

- [ ] **Step 2: Edit `skills/write-a-test-plan/SKILL.md` line 8**

`old_string`:

```
Generate a comprehensive testing plan by searching the conversation and project context for PRDs, implementation plans, triage documents, and issues. Output is a Markdown file in `~/Development/docs/test-plans/`.
```

`new_string`:

```
Generate a comprehensive testing plan by searching the conversation and project context for PRDs, implementation plans, triage documents, and issues.
```

Rationale: line 64 already has the "Ask the user where they'd like to save this" pattern.

- [ ] **Step 3: Edit `skills/write-a-plan/SKILL.md` line 3 (frontmatter description)**

`old_string`:

```
description: Create a robust implementation plan from scratch through relentless interviewing, codebase exploration, and vertical slicing. Saves to ./plans/. Use when user wants to write a plan, create an implementation plan, plan a feature, or needs to think through how to build something — without requiring a PRD first.
```

`new_string`:

```
description: Create a robust implementation plan from scratch through relentless interviewing, codebase exploration, and vertical slicing. Use when user wants to write a plan, create an implementation plan, plan a feature, or needs to think through how to build something — without requiring a PRD first.
```

Rationale: `Saves to ./plans/.` contradicts line 76 which asks the user for a destination.

- [ ] **Step 4: Edit `skills/prd-to-plan/SKILL.md` — two edits in one file**

Edit 4a — line 3 (frontmatter description).

`old_string`:

```
description: Turn a PRD into a multi-phase implementation plan using tracer-bullet vertical slices, saved as a local Markdown file in ./plans/. Use when user wants to break down a PRD, create an implementation plan, plan phases from a PRD, or mentions "tracer bullets".
```

`new_string`:

```
description: Turn a PRD into a multi-phase implementation plan using tracer-bullet vertical slices. Use when user wants to break down a PRD, create an implementation plan, plan phases from a PRD, or mentions "tracer bullets".
```

Edit 4b — line 8 (body intro).

`old_string`:

```
Break a PRD into a phased implementation plan using vertical slices (tracer bullets). Output is a Markdown file in `./plans/`.
```

`new_string`:

```
Break a PRD into a phased implementation plan using vertical slices (tracer bullets).
```

Rationale: line 72 already has the "Ask the user where they'd like to save this" pattern.

- [ ] **Step 5: Verify no hardcoded paths remain**

```bash
grep -rn 'Development/docs' skills/
grep -rn 'Saves to \./plans/\|in \`./plans/\`\|Markdown file in ./plans/' skills/
```

Expected: first `grep` prints no output (exit 1). Second `grep` prints no output. If either prints a match, the corresponding edit didn't land — fix before committing.

- [ ] **Step 6: Verify the "ask the user" sections are still intact (regression check)**

```bash
grep -rn "Ask the user where they'd like to save" skills/
```

Expected: at least 4 matches — one each in `improve-codebase-architecture/SKILL.md`, `write-a-test-plan/SKILL.md`, `write-a-plan/SKILL.md`, `prd-to-plan/SKILL.md`, plus `write-a-prd/SKILL.md`. If any are missing, one of our edits accidentally removed a bystander section.

- [ ] **Step 7: Commit**

```bash
git add skills/improve-codebase-architecture/SKILL.md skills/write-a-test-plan/SKILL.md skills/write-a-plan/SKILL.md skills/prd-to-plan/SKILL.md
git commit -m "$(cat <<'EOF'
fix: remove hardcoded output paths from 4 skills

improve-codebase-architecture, write-a-test-plan, write-a-plan, and prd-to-plan
had opening-paragraph assertions about saving to ~/Development/docs/* or ./plans/
that contradicted the "Ask the user where they'd like to save" sections already
in their bodies. The stale assertions were holdovers from before the flexible
document storage migration (#1) and broke the skills for anyone but the author.
EOF
)"
```

- [ ] **Step 8: Verify commit and tree state**

```bash
git log -1 --stat
git status
```

Expected: latest commit touches exactly the four SKILL.md files; working tree clean.

---

### Task 4: End-to-end verification

**No code changes — verification only. Do NOT commit anything in this task.**

Goal: confirm the plugin actually installs and the skills actually load. If any check fails, STOP and report the exact failure to the user before making further changes.

- [ ] **Step 1: Confirm the worktree is ready**

```bash
git status
git log --oneline -5
```

Expected: clean working tree; the 3 commits from Tasks 1–3 are in the log.

- [ ] **Step 2: Install the plugin from the local worktree path**

In a fresh Claude Code session (same machine — this REPL or a new one):

```
/plugin marketplace add /Users/evansst/Development/skills/.claude/worktrees/agitated-agnesi
/plugin install skills@evans-sam-skills
```

Expected: both commands succeed without error. If you see `source does not exist` or `marketplace.json not found`, Task 1 failed — go back and check the file.

- [ ] **Step 3: Verify the install was registered in Claude's state files**

```bash
jq '.plugins["skills@evans-sam-skills"]' ~/.claude/plugins/installed_plugins.json
jq '."evans-sam-skills"' ~/.claude/plugins/known_marketplaces.json
```

Expected: first command returns a non-null array with at least one install record (`installPath`, `version`, `installedAt`, etc.). Second command returns an object with a `source` field.

- [ ] **Step 4: Check the plugin is enabled**

```bash
jq '.enabledPlugins["skills@evans-sam-skills"]' ~/.claude/settings.json
```

Expected: `true`. (If `null`, the install succeeded but the plugin is disabled — user can `/plugin enable skills@evans-sam-skills`.)

- [ ] **Step 5: Start a fresh Claude Code session and check skill discovery**

Open a new terminal or run `claude` again. In the new session, inspect the available-skills list in the system prompt (or ask Claude "What skills do you have access to?"). Expected entries include `skills:tdd`, `skills:write-a-plan`, `skills:grill-me`, `skills:write-a-skill`, `skills:troubleshoot`, etc. — all 19 skills from this repo, each prefixed with `skills:`.

If a skill is missing, check its SKILL.md has valid YAML frontmatter (`name:` and `description:`).

- [ ] **Step 6: Smoke-test one skill invocation**

In the fresh session, invoke `skills:tdd` via the Skill tool. Expected: the skill content loads, and any sibling references it mentions (e.g., `tests.md`, `mocking.md`, `refactoring.md`) are mentioned as readable from within the plugin directory. Do NOT actually run a TDD workflow — just confirm the skill loads.

- [ ] **Step 7: Spot-check one fixed skill**

Invoke `skills:improve-codebase-architecture` via the Skill tool. Expected: the opening prose no longer contains `~/Development/docs/rfc`, and the body still includes the "Ask the user where they'd like to save this RFC" section.

- [ ] **Step 8: Cleanup (optional — ask user first)**

If everything above passed, the user may want to remove the symlinks at `~/.claude/skills/*` (which point into `~/.agents/skills/`) so each skill has a single canonical plugin-installed copy instead of competing user-level + plugin-level versions. Do NOT do this without explicit user confirmation — it's their environment.

```bash
# Only run after user confirms:
ls -la ~/.claude/skills/ | grep -E '-> .*\.agents/skills/'
```

Expected (if they confirm): a list of symlinks to review. The user decides which to keep.

- [ ] **Step 9: Push and verify GitHub install (optional, end-of-feature)**

Once Tasks 1–3 are pushed to `main` on GitHub, run from a fresh session:

```
/plugin marketplace uninstall evans-sam-skills
/plugin marketplace add evans-sam/skills
/plugin install skills@evans-sam-skills
```

Expected: the second command fetches from GitHub (not the local path) and installs cleanly. This proves the "fresh user on any machine" install path works end-to-end.

---

## Rollback

If any task lands and is later found to be broken, the task-per-commit structure means a single `git revert <sha>` can undo it cleanly. No shared state between tasks.

## Self-review notes

- **Spec coverage:** Every item in `/Users/evansst/.claude/plans/mellow-spinning-frost.md`'s "Changes" section has a corresponding task. Out-of-scope items are not in the plan.
- **No placeholders:** Every edit shows the exact `old_string` and `new_string`. No "TBD" or "fill in."
- **Type consistency:** `name` is `skills` everywhere it should be (`plugin.json`, `marketplace.json.plugins[0].name`); marketplace name `evans-sam-skills` is consistent across `marketplace.json.name` and the install command in README.
