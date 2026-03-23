# Agent Skills

A collection of agent skills that extend capabilities across planning, development, and tooling.

## Docs Repo Setup

Several skills save persistent documents (PRDs, issues, test plans, RFCs, plans) to a shared
GitHub docs repo. Documents are organised by the project they relate to:

```
<DOCS_PATH>/
└── <github-org>/
    └── <github-repo>/
        ├── prd/
        ├── issues/
        ├── test-plans/
        ├── rfc/
        └── plans/
```

Skills detect the current project automatically from `git remote get-url origin` and commit +
push after every write, so documents stay in sync across all devices and cloud environments.

### Configuration

Set these environment variables in `~/.claude/settings.json`:

```json
{
  "env": {
    "DOCS_REPO": "your-username/docs",
    "DOCS_PATH": "~/Development/docs"
  }
}
```

`DOCS_PATH` is optional and defaults to `~/Development/docs`.

### One-time setup

```bash
# Create a new private GitHub repo at https://github.com/new, then:
git clone git@github.com:your-username/docs.git ~/Development/docs
```

### In a new cloud environment

```bash
git clone git@github.com:your-username/docs.git ~/Development/docs
```

That's it — skills create per-project subdirectories automatically on first use.

## Installation

Install all skills using the [Vercel skills CLI](https://github.com/vercel-labs/skills):

```bash
npx skills@latest add evans-sam/skills
```

Or install individual skills:

```bash
npx skills@latest add evans-sam/skills --skill write-a-plan --skill tdd
```

You can also install the CLI globally:

```bash
npm i -g skills
skills add evans-sam/skills
```

Skills are installed to `~/.claude/skills/` and available immediately in Claude Code.

## Planning & Design

These skills help you think through problems before writing code.

- **write-a-prd** — Create a PRD through an interactive interview, codebase exploration, and module design. Filed as a markdown doc in `~/Development/docs/prd`.
- **write-a-plan** — Create a robust implementation plan from scratch through relentless interviewing, codebase exploration, and vertical slicing. No PRD required. Saves to `./plans/`.
- **prd-to-plan** — Turn a PRD into a multi-phase implementation plan using tracer-bullet vertical slices. Saves to `./plans/`.
- **prd-to-issues** — Break a PRD into independently-grabbable markdown docs in `~/Development/docs/issues` using vertical slices.
- **write-a-test-plan** — Create a comprehensive testing plan from a PRD, implementation plan, or triage document. Covers local data setup, required services, acceptance tests, and edge cases.
- **design-an-interface** — Generate multiple radically different interface designs for a module using parallel sub-agents. Great for exploring API shapes and comparing trade-offs.
- **request-refactor-plan** — Create a detailed refactor plan with tiny commits via user interview. Saves as a local markdown RFC document.
- **grill-me** — Get relentlessly interviewed about a plan or design until every branch of the decision tree is resolved.
- **ubiquitous-language** — Extract a DDD-style ubiquitous language glossary from the current conversation, flagging ambiguities and proposing canonical terms. Saves to `UBIQUITOUS_LANGUAGE.md`.

## Development

These skills help you write, refactor, and fix code.

- **tdd** — Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **triage-issue** — Investigate a bug by exploring the codebase, identify the root cause, and file a markdown doc in `~/Development/docs/issues` with a TDD-based fix plan.
- **improve-codebase-architecture** — Explore a codebase for architectural improvement opportunities, focusing on deepening shallow modules and improving testability.

## Tooling & Setup

- **setup-pre-commit** — Set up Husky pre-commit hooks with lint-staged, Prettier, type checking, and tests.
- **git-guardrails-claude-code** — Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, etc.) before they execute.

## Meta

- **write-a-skill** — Create new skills with proper structure, progressive disclosure, and bundled resources.
