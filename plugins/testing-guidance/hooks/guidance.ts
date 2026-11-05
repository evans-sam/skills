export const DEFAULT_SOURCE = ''

export type Guidance = {
  /** Markdown body, no outer wrapper. */
  text: string
  /** Where it came from: a URL or a file path; empty for the bundled copy. */
  source: string
  /** The source's own last-edited date, when known. */
  editedAt?: string
  /** When the copy was taken, ISO 8601; absent for the bundled copy. */
  syncedAt?: string
}

const APPLY =
  'Apply this whenever tests are written, reviewed, or planned, including test plans and the testing sections of PRDs and implementation plans.'

// The message the model reads: a tagged wrapper, a provenance line, the body.
export const render = (guidance: Guidance) => {
  const edited = guidance.editedAt ? `, last edited ${guidance.editedAt}` : ''
  const synced = guidance.syncedAt ? `, synced ${guidance.syncedAt.slice(0, 10)}` : ''
  const provenance =
    guidance.source === ''
      ? `Bundled default guidance. ${APPLY}`
      : `Source: ${guidance.source}${edited}${synced}. ${APPLY}`

  return `<testing-guidance>
# Testing guidance

${provenance}

${guidance.text.trim()}
</testing-guidance>`
}

// A sanitized condensation of an internal testing guide. The sync subcommand
// replaces it for one machine; editing it here ships a new default.
export const DEFAULT_BODY = `## The one idea

Every test checks inputs and outputs: a unit test of a method, an integration test of a service, an e2e test of the system. A test that doesn't drive a real browser against a deployed system isn't e2e (framework-scaffolded \`*.e2e-spec.ts\` files are integration tests). One touching a database isn't unit.

## The tiers at a glance

- Unit: does this method do what it claims? Every PR and local run, one process, no I/O, milliseconds. Blocks the PR.
- Integration: does this service keep its promises to callers? Every PR, one machine, dependencies in containers (database, cache, Localstack), under 5 to 8 minutes. Blocks the PR.
- E2E: can a user complete a journey across the system? Scheduled after shipping, deployed environment, headless browser, minutes. Pages the team.
- Production monitoring isn't a test: it watches real users and pages on-call.

## Unit tests

Arguments in, return value or thrown error out. Needing anything running, even an empty database, disqualifies it.

May: call the method under test; build inputs in plain code; pass fakes for dependencies; run in parallel with every other unit test.
May never: touch a database; make a network call; read or write files; depend on another test running first.

Catches logic: edge cases, off-by-one errors, wrong branches, date math, unhandled nulls, missing throws. Be exhaustive: it's the only tier fast enough. Never catches wiring: wrong queries, unrun migrations, mismatched field names. Needing factories, test-module builders, or beforeEach wiring means you're testing a service.

## Integration tests

May: boot the whole service; use a real database, cache, and migrations; run internal services as prebuilt images; call its public interface as callers do; seed its own data, then assert on it.
May never: cross the internet (use nock); talk to a real third party, even a sandbox; mock a database call; depend on a shared or deployed environment; reach around the interface to trigger behavior; assert on data it didn't create.

Each repo (one backend, several frontends) has its own ring: the API server with Postgres and Redis, or a frontend app with an API server image, driven the way a browser would. Everything runs in Docker on one machine, torn down afterward. Reach containers by Docker Compose DNS name (\`API_URL=http://api:3000\`) so a pass proves which server answered. Nock intercepts third parties at the network boundary: an SMS provider, a payments provider, an insurance-eligibility vendor, a cloud service your local emulator lacks.

Rule of thumb: it passes on an airplane with no wifi.

With nock, match the outbound body (formatted phone number, right fields) and check \`nock.isDone()\`; it can also prove a call didn't happen. After a POST or PUT, check the response, then query the database for stored values.

Catches wiring: wrong queries, missing or hand-written migrations, wrong-role guards, unformatted outbound requests. Never catches what's outside the box: bad deploys, expired certs, vendor outages or contract changes, cross-app journeys.

## E2E tests

A real user action in a real browser against the deployed system, asserting what the user was promised. Nothing is under your control, so it catches what no other tier can and is the slowest, most fragile.

May: drive a real browser through deployed apps; cross app boundaries in one journey; seed through the system's own APIs; cover a critical happy path.
May never: mock, intercept, or fake anything; reach into a database to set up or assert; assume data exists that it didn't create; try to be exhaustive.

Few tests, happy paths only, each a journey the business can't afford to break: can the user do the thing? The suite changes only for major additions. Catches seams, like a renamed field one frontend missed. It detects rather than prevents, and a failure says only that something broke.

## Deciding which tier to write

- One method's logic and edge cases: unit, exhaustively.
- Wiring, including third-party calls and a UI calling the API: integration, a new test per endpoint, screen, or behavior.
- A critical cross-app journey: e2e, rarely.

When planning or reviewing tests, label each case by tier, say what the integration ring runs and what nock intercepts, and push edge cases to the cheapest tier that proves them.`

export const DEFAULT_GUIDANCE: Guidance = {
  text: DEFAULT_BODY,
  source: DEFAULT_SOURCE,
}
