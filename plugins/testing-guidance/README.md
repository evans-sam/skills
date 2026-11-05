# testing-guidance

Puts a team's testing guidance in front of Claude the first time a session writes or plans tests, and keeps it out of sessions that never do.

The bundled guidance defines three tiers (a unit test checks a method, an integration test checks a service, an e2e test checks the system), the rules each tier may and may never break, and how to decide which tier a case belongs to. It names no organization, product, or vendor; `/testing-guidance sync` replaces it with your own document.

## When it loads

- A prompt that mentions tests, specs, coverage, TDD, a test plan, or a test runner (jest, vitest, playwright, cypress, supertest, nock) loads the guidance before the turn starts, as a hidden message the model reads. A toast says so.
- A Write or Edit to a test file (`*.spec.*`, `*.test.*`, `*.e2e-spec.*`, or anything under `__tests__/`, `test/`, `tests/`, `e2e/`, `cypress/`, `playwright/`) when the guidance isn't in that conversation yet loads it and refuses that one write, so the file is written after the guidance is read. Subagents get their own copy.
- `/testing-guidance` loads it on demand, again if already loaded.

Each conversation gets the guidance once per session. Nothing is injected at session start.

## Using your own guidance

The plugin never reads a document service itself; it carries text. Two ways to change that text:

`/testing-guidance sync <source>` replaces the copy on your machine. The command hands the assistant an instruction: fetch the source (a Notion URL through the Notion connector, an http(s) URL through WebFetch, anything else as a local file), condense it to the plugin's rubric (every definition and rule kept, media and comments dropped, 600 to 1200 words), and hand the result back through the plugin's `set_guidance` tool. The plugin stores it in its own store under `~/.claude`, loads it into the current conversation, and uses it instead of the bundled copy from then on. Once a source is stored, `/testing-guidance sync` with no argument re-syncs from it.

Editing `hooks/guidance.ts` and bumping the version in `plugin.json` ships a new bundled default to everyone who installs or updates. After a sync in a checkout of this repo, the assistant offers to make that edit too.

`/testing-guidance status` says which copy is in force and where it came from; `/testing-guidance show` prints it; `/testing-guidance reset` drops the synced copy and returns to the bundled one.

## Install

At the prompt of a terminal session:

```
/plugin install testing-guidance --marketplace evans-sam/skills
```

From a shell:

```
claude plugin install testing-guidance --marketplace evans-sam/skills
```

In the desktop app, where `/plugin` does not run: click + next to the prompt box, then Plugins, Add marketplace with `evans-sam/skills`, then Add plugin.

This plugin is a hooks module (Claude Code's function hooks, an early-access surface), so it needs a Claude Code build that loads them; `claude plugin validate plugins/testing-guidance` says whether yours does.

## Development

`claude plugin validate <this folder>` checks the module; `claude plugin test <this folder>` runs `hooks/testing-guidance.test.ts`.
