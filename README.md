# Agent Skills

A collection of agent skills that extend capabilities across planning, development, and tooling.

## Installation

Install as a Claude Code plugin:

```
/plugin marketplace add evans-sam/skills
/plugin install skills@evans-sam-skills
```

Skills are available immediately as `skills:<skill-name>` after installation.

## docs-vault plugin

This repo also publishes `docs-vault`, a plugin that routes the documents these skills produce (plans, specs, PRDs, test plans, triage write-ups) into one docs vault instead of the code repo: a session-start rule, a write-guard hook, and `/docs-vault:setup`. See [plugins/docs-vault](./plugins/docs-vault/README.md).

```
/plugin install docs-vault@evans-sam-skills
```

## Planning & Design

These skills help you think through problems before writing code.

- **write-a-prd** — Create a PRD through an interactive interview, codebase exploration, and module design. Saves wherever you tell it — local file, GitHub wiki, Notion, Confluence, etc.
- **write-a-plan** — Create a robust implementation plan from scratch through relentless interviewing, codebase exploration, and vertical slicing. No PRD required.
- **prd-to-plan** — Turn a PRD into a multi-phase implementation plan using tracer-bullet vertical slices.
- **prd-to-issues** — Break a PRD into independently-grabbable issues using vertical slices. Creates GitHub issues directly, or saves to a location of your choice.
- **write-a-test-plan** — Create a comprehensive testing plan from a PRD, implementation plan, or triage document. Covers local data setup, required services, acceptance tests, and edge cases.
- **design-an-interface** — Generate multiple radically different interface designs for a module using parallel sub-agents. Great for exploring API shapes and comparing trade-offs.
- **request-refactor-plan** — Create a detailed refactor plan with tiny commits via user interview. Saves as a local markdown RFC document.
- **grill-me** — Get relentlessly interviewed about a plan or design until every branch of the decision tree is resolved.
- **blueprint-scratchpad** — Start the shaping period for a feature blueprint. Fetches Linear project context and linked docs, grills the engineer on the full problem space, and produces a working scratchpad. Supports multi-session check-ins.
- **blueprint-draft** — Transform a shaping scratchpad into a formal engineering blueprint with decided language, collaborative estimation, and Linear ticket linking.
- **blueprint-publish** — Curate a working blueprint and scratchpad into a team-ready Notion page with section-by-section review before publishing.
- **ubiquitous-language** — Extract a DDD-style ubiquitous language glossary from the current conversation, flagging ambiguities and proposing canonical terms. Saves to `UBIQUITOUS_LANGUAGE.md`.

## Development

These skills help you write, refactor, and fix code.

- **tdd** — Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **triage-issue** — Investigate a bug by exploring the codebase, identify the root cause, and create an issue with a TDD-based fix plan. Creates a GitHub issue directly, or saves to a location of your choice.
- **improve-codebase-architecture** — Explore a codebase for architectural improvement opportunities, focusing on deepening shallow modules and improving testability.

## Tooling & Setup

- **setup-pre-commit** — Set up Husky pre-commit hooks with lint-staged, Prettier, type checking, and tests.
- **git-guardrails-claude-code** — Docs for the bundled git/gh guardrails hook (what it blocks and how to customize). The hook itself is shipped as part of this plugin — no manual install.

## Bundled Hooks

Installing this plugin automatically enables:

- **Git & GitHub CLI guardrails** — a `PreToolUse` hook that blocks dangerous `git` (push, reset --hard, clean, branch -D, etc.) and `gh` (repo delete, pr merge, secret set, API mutations, etc.) commands before they run. Customize with `GIT_GUARDRAILS_EXTRA_PATTERNS`, `GIT_GUARDRAILS_ALLOW_PATTERNS` and `GIT_GUARDRAILS_DISABLE` in the `env` block of `~/.claude/settings.json`. See the [git-guardrails-claude-code skill](skills/git-guardrails-claude-code/SKILL.md) for the full block list.

If you installed this hook by hand from an earlier version of the skill, remove the `PreToolUse` entry that points at `~/.claude/hooks/block-dangerous-git.sh` from your `settings.json` and delete that script; otherwise both copies run on every command.

## Meta

- **write-a-skill** — Create new skills with proper structure, progressive disclosure, and bundled resources.
