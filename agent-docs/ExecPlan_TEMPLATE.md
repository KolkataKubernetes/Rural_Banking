# <Short, action-oriented description>

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document must be maintained in accordance with `agent-docs/PLANS.md` from the repository root.

## Purpose / Big Picture

Explain in a few sentences what someone gains after this change and how they can see it working. State the user-visible behavior you will enable.

## Progress

Use a list with checkboxes to summarize granular steps. Every stopping point must be documented here, even if it requires splitting a partially completed task into two (“done” vs. “remaining”). This section must always reflect the actual current state of the work.

- [ ] (YYYY-MM-DD HH:MMZ) Example incomplete step.
- [ ] Example partially completed step (completed: X; remaining: Y).

## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during implementation. Provide concise evidence.

- Observation: ...
  Evidence: ...

## Decision Log

Record every decision made while working on the plan in the format:

- Decision: ...
  Rationale: ...
  Date/Author: ...

## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion. Compare the result against the original purpose.

## Context and Orientation

Describe the current state relevant to this task as if the reader knows nothing. Name the key files and modules by full path. Define any non-obvious term you will use. Do not refer to prior plans.

## Plan of Work

Describe, in prose, the sequence of edits and additions. For each edit, name the file and location (function, module) and what to insert or change. Keep it concrete and minimal.

## Concrete Steps

State the exact commands to run and where to run them (working directory). When a command generates output, show a short expected transcript so the reader can compare. This section must be updated as work proceeds.

## Validation and Acceptance

Describe how to start or exercise the system and what to observe. Phrase acceptance as behavior, with specific inputs and outputs. If tests are involved, say “run <project’s test command> and expect <N> passed; the new test <name> fails before the change and passes after”.

## Idempotence and Recovery

If steps can be repeated safely, say so. If a step is risky, provide a safe retry or rollback path. Keep the environment clean after completion.

## Artifacts and Notes

Include the most important transcripts, diffs, or snippets as indented examples. Keep them concise and focused on what proves success.

## Data Contracts, Inputs, and Dependencies

Be explicit about concrete dependencies and observable contracts, not abstract interfaces.

For each dependency, specify (1) the library or tool to use (and version constraints if relevant), (2) where it is used in the repository (file paths), (3) what concrete inputs it consumes (files, tables, data frames, parameters), and (4) what concrete outputs or side effects it produces.

When a script or function is central to the plan, specify its contract in operational terms: (1) required inputs (file paths, column names, schemas, assumptions), (2) outputs (files written, tables updated, objects returned), and (3) invariants that must hold (e.g., row counts preserved, keys unique, CRS unchanged).

Prefer describing contracts through data artifacts rather than code structure. Do not introduce new abstraction layers, interfaces, or class hierarchies unless explicitly requested.

If a dependency choice affects results (e.g., GeoPandas vs. Shapely operations, DuckDB vs. pandas), state the reason for the choice and the expected behavioral implications.

## Change Notes

If this plan is revised, add a dated note here describing what changed and why.
