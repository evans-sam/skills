---
name: prd-to-issues
description: Break a PRD into independently-grabbable implementation issues using tracer-bullet vertical slices. Use when user wants to convert a PRD to issues, create implementation tickets, or break down a PRD into work items.
---

# PRD to Issues

Break a PRD into independently-grabbable implementation issues using vertical slices (tracer bullets).

## Process

### 1. Locate the PRD

Ask the user for the PRD file path (likely in `~/Development/docs/prd/`). The user may also provide links to Linear issues/projects, Figma designs, or Notion documents for additional context.

If the PRD is not already in your context window, read it from the provided file path.

### 2. Gather external context

If the user provided references to external tools, use the available MCP tools to pull in additional context:

- **Linear**: The user may provide ticket codes (e.g., `EO-1234`) or URLs. Fetch related issues, project details, or initiative context to understand scope, dependencies, and prior decisions.
- **Figma**: The user may provide a Figma URL. Fetch design context and screenshots to understand UI requirements and component boundaries for each slice.
- **Notion**: The user may provide page titles or URLs. Search Notion by title if no URL is given. Fetch documents for supplementary specs, notes, or research.

Use this context to inform how you break the PRD into slices. If no external references are provided, skip this step.

### 3. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code.

### 4. Draft vertical slices

Break the PRD into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as an architectural decision or a design review. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 5. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 6. Create the issue documents

For each approved slice, save a markdown file in `~/Development/docs/issues/`. Use a kebab-case filename derived from the slice title (e.g., `add-user-auth-flow.md`). Use the issue body template below.

Create issues in dependency order (blockers first) so you can reference filenames in the "Blocked by" field.

After saving all issue files, commit and push them:

```bash
cd ~/Development/docs && git add issues/ && git commit -m "Add issues for: <PRD name>" && git push
```

<issue-template>
## Parent PRD

`<prd-filename>` (in `~/Development/docs/prd/`)

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation. Reference specific sections of the parent PRD rather than duplicating content.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- Blocked by `<issue-filename>` (if any)

Or "None - can start immediately" if no blockers.

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7

</issue-template>

Do NOT modify the parent PRD document.
