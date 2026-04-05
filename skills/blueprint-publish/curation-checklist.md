# Curation Checklist

Watch for these issues during the curation pass. Flag them to the user before publishing.

## Language & Tone

- [ ] No hedging language above the fold ("maybe," "we might consider," "potentially")
- [ ] No cheerful AI filler or emoji
- [ ] Decided, confident tone throughout — "We will," not "We propose"
- [ ] Scratchpad items that leaked into above-the-fold sections

## Structure & Readability

- [ ] Golden rule: can someone understand the whole thing in under 10 minutes?
- [ ] No section is a wall of prose where a diagram would communicate faster
- [ ] Context & Problem Statement is a few short paragraphs, not an essay
- [ ] Non-goals are scope boundaries, not negatives ("don't crash the app")

## Technical Implementation

- [ ] Services, tables, endpoints are named concretely — no vague references
- [ ] No code spelunking (tracing through call chains line by line) — that belongs in the scratchpad
- [ ] Organized by subsections: Build New, Changed Tables, Extend Existing, Frontend, Technical Improvements

## Estimates

- [ ] Every row has a meaningful description (not just a title)
- [ ] Every row maps to work in Technical Implementation
- [ ] Every item in Technical Implementation maps to an estimate row
- [ ] Testing time is included
- [ ] Total matches demo date
- [ ] Linear ticket links are included where available

## Key Decisions

- [ ] Each decision includes: what was decided, alternatives considered, why
- [ ] No non-decisions ("We decided to use TypeScript" without a genuine alternative)
- [ ] Trade-offs are articulated — if you can't state the trade-off, the decision isn't ready

## Risks & Open Questions

- [ ] Unresolved items from scratchpad appear here with a stated default approach
- [ ] Dependencies on other teams are called out
- [ ] Assumptions are listed explicitly

## Rollback Plan

- [ ] How to revert is documented
- [ ] Irreversible components are called out
- [ ] Feature flag strategy is described (if applicable)
