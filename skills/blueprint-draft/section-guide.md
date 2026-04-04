# Section Guide

Per-section guidance for the blueprint drafting grill. For each section: synthesize from the scratchpad, present a draft, grill on gaps, get approval, write to the blueprint doc.

## Litmus Tests (apply to every section)

- Could a senior engineer on another team understand this without asking you questions?
- Is everything above the fold written as a decided plan, not a brainstorm?
- Can someone read the full blueprint in under 10 minutes?

---

## 1. Context & Problem Statement

**Synthesize from scratchpad:** Problem understanding, why now, current state.

**Push for:**
- Three clear questions answered: What problem? Why now? Current pain?
- Short paragraphs. Anyone at the company should understand this.
- Project phasing context if this is part of a larger initiative.

**Challenge:**
- Over-explanation. If it takes more than a few paragraphs, you may be bundling too many problems.
- Missing "why now" — a problem without urgency context floats in space.

**Good example:** The Dynamic Queue blueprint nails this. A few short paragraphs, phasing context, readable by anyone.

## 2. Goals & Non-Goals

**Synthesize from scratchpad:** Desired outcome, scope boundaries.

**Push for:**
- Goals that are specific and measurable. "Validate X in production" is good. "Improve the system" is not.
- Non-goals that are scope shields — things someone might reasonably expect but you're choosing not to do.

**Challenge:**
- Non-goals that are just negatives ("don't break the app"). Those aren't boundaries.
- Goals that can't be verified. If you can't tell when you're done, the goal isn't specific enough.

## 3. Proposed Approach

**Synthesize from scratchpad:** Initial approach ideas, refined through shaping.

**Push for:**
- A plain-language mental model. "If you had to explain this to a PM over coffee in a few minutes, what would you say?"
- Diagrams. ASCII flow diagrams, sequence diagrams, system diagrams. They communicate faster than paragraphs.
- Analogies where they help (the Dynamic Queue example uses a "waiting room at a clinic" analogy).

**Challenge:**
- Jumping into code-level details. Save that for Technical Implementation.
- Missing diagram where one would communicate faster. Ask: "Can you describe the flow? Want me to sketch an ASCII diagram?"

## 4. Technical Implementation Details

**Synthesize from scratchpad:** Approach ideas, spike findings, decisions made.

**Organize by subsections:**
- Build New Services
- New/Changed Tables
- Extend Existing Capabilities
- Frontend Changes
- Technical Improvements/Foundation Work

Skip subsections that don't apply.

**Push for:**
- Concrete names. Name the services, tables, columns, endpoints. "MatchMakingService" not "a matching service."
- Statements of intent: "MatchMakingService — Responsible for matching patients and physicians on-demand."
- Enum values, feature flag names, API endpoint paths.

**Challenge:**
- "Maybe" language. "We might consider..." doesn't belong above the fold. Decide or move to Risks/Open Questions.
- Code spelunking. Walking through call chains line-by-line is research, not a plan. Summarize the approach; put the deep-dive in the scratchpad.
- Proposals instead of decisions. "We propose moving X to Y" — did you decide or not?

**Codebase exploration:** Only when the user directs it. Read the code, summarize findings, ask how it affects the blueprint.

## 5. Data <> Engineering Needs

**Push for:**
- New data pipelines or ETL changes
- Schema changes affecting analytics
- Event tracking requirements
- Data backfills needed
- ML model dependencies
- Hex dashboards or reporting needs
- Tag data team contacts if known

**Challenge:**
- "None" without thinking it through. Most features have analytics or tracking needs.

## 6. Rollback Plan

**Push for:**
- How to revert if something goes wrong. A few bullets.
- Anything irreversible (destructive migrations, third-party calls, data that can't be un-sent).
- Feature flag strategy if applicable.

**Challenge:**
- Missing irreversibility disclosure. If there are destructive migrations, the team needs to know.

## 7. Key Decisions & Trade-offs

**Push for:**
- For each significant decision: what you decided, alternatives considered, why this path.
- The "why" is the most valuable part — it captures reasoning that would otherwise be lost.

**Challenge:**
- Decisions where the trade-off isn't articulated. "If you can't articulate the trade-off, you probably haven't thought through the decision deeply enough."
- Non-decisions. "We decided to use TypeScript" isn't worth documenting unless there was a genuine alternative.
- Padding with obvious choices.

## 8. Risks, Open Questions & Assumptions

**Push for:**
- What could change this plan?
- What haven't you validated yet?
- What are you assuming to be true?
- Dependencies on other teams.
- Unresolved scratchpad items land here with a stated default approach.

**Challenge:**
- Empty risks section. Every project has risks. Push harder.
- Assumptions masquerading as facts. "The API will handle our scale" — have you verified this?

## 9. Feature Demo Plan

**This is a stub.** The testing plan is out of scope for this skill.

**Write:**
- A link placeholder for the companion testing plan.
- Remind the user: "Fill this out before your demo date using `write-a-test-plan`."
