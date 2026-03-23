# Resolve Docs Path

Use this procedure whenever a skill needs to read from or write to the persistent docs repo.

## Step 1 — Resolve the docs repo config

Read the following from the environment:

- `DOCS_REPO` — GitHub repo slug for the shared docs repo (e.g. `evans-sam/docs`).
- `DOCS_PATH` — Local clone path. Defaults to `~/Development/docs` if unset.

If `DOCS_REPO` is not set, ask the user:

> "What is your GitHub docs repo? (e.g. `evans-sam/docs`)"

Then remind them:

> "Set `DOCS_REPO=evans-sam/docs` in your Claude Code settings (`~/.claude/settings.json` under `env`) so you're not asked again."

Verify `$DOCS_PATH` is a git repo cloned from `$DOCS_REPO`. If the directory doesn't exist or
is not a git repo, tell the user:

```bash
git clone git@github.com:$DOCS_REPO.git $DOCS_PATH
```

## Step 2 — Detect the current project

Run the following in the working directory to get the remote URL:

```bash
git remote get-url origin
```

Parse the org/repo slug from the output. Handle both formats:

- SSH: `git@github.com:org/repo.git` → `org/repo`
- HTTPS: `https://github.com/org/repo.git` → `org/repo`

Strip the `.git` suffix if present.

If the working directory is not a git repo or has no `origin` remote, ask the user:

> "Which project is this doc for? (e.g. `evans-sam/my-app`)"

## Step 3 — Compute the doc root

```
<doc-root> = $DOCS_PATH/<org>/<repo>/
```

Create the directory if it doesn't exist:

```bash
mkdir -p <doc-root>/{prd,issues,test-plans,rfc,plans}
```

## Step 4 — Pull before reading

Before reading any existing doc, pull the latest from the docs repo:

```bash
git -C $DOCS_PATH pull
```

## Step 5 — Commit and push after writing

After writing or updating a file, stage, commit, and push:

```bash
git -C $DOCS_PATH add <relative-path-within-docs-repo>
git -C $DOCS_PATH commit -m "docs(<org>/<repo>): <message>"
git -C $DOCS_PATH push
```

Use a descriptive commit message that includes the project slug, e.g.:

- `docs(evans-sam/my-app): add PRD user-onboarding`
- `docs(evans-sam/my-app): triage broken-auth-redirect`
- `docs(evans-sam/my-app): add RFC extract-auth-module`
