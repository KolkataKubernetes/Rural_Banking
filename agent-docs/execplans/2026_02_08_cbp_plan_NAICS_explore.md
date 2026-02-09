# Investigate `naics == "00"` in `CBP_all.rds`

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this work, a contributor can point to the exact step in the CBP pipeline where `naics == "00"` appears in `2_processed_data/CBP_all.rds`, determine whether those records come directly from Census CBP pulls or are introduced during downstream cleaning/joins, and document the result in a reproducible way. Success is visible when a single diagnostic output (or log section in the script) reports counts of `naics == "00"` by year and confirms the first script stage where those rows exist.

## Progress

- [x] (2026-02-08 23:33Z) Created this execplan file and aligned structure to `agent-docs/PLANS.md`.
- [ ] Confirm the authoritative CBP artifact path and schema contract used by downstream scripts (`2_processed_data/CBP_all.rds` and any staging objects).
- [ ] Trace the CBP ingest and processing chain to locate where the `naics` column is created or transformed.
- [ ] Add a reproducible diagnostic block that counts and inspects `naics == "00"` at each relevant stage.
- [ ] Run the diagnostic workflow and record findings in this plan.
- [ ] Document whether `naics == "00"` is expected raw CBP behavior or an unintended transformation in repository code.

## Surprises & Discoveries

- Observation: The repository currently contains `2_processed_data/CBP_all.rds` (uppercase `CBP`) rather than a lowercase `cbp_all.rds` file.
  Evidence: `rg --files | rg -n "cbp_all\\.rds|CBP_all\\.rds"` returns `2_processed_data/CBP_all.rds`.

## Decision Log

- Decision: Scope this plan to diagnosis first, not corrective edits.
  Rationale: The immediate request is to figure out what is causing `naics == "00"`; correction requires confirmed root cause.
  Date/Author: 2026-02-08 / Codex
- Decision: Treat `2_processed_data/CBP_all.rds` as the active target artifact unless the user identifies a different file.
  Rationale: It is the only matching artifact currently present in the repository.
  Date/Author: 2026-02-08 / Codex

## Outcomes & Retrospective

No diagnostic execution has been completed yet. This plan currently defines the reproducible investigation path and acceptance criteria for identifying root cause.

## Context and Orientation

The CBP pipeline centers on `1_code/1_0_ingest/census_CBP.R`, which pulls and assembles Wisconsin County Business Patterns data. A downstream artifact `2_processed_data/CBP_all.rds` is used in later analysis workbooks. In this plan, “root cause” means the earliest script stage where rows with `naics == "00"` are present. The investigation must separate three possibilities: (1) CBP API/source data includes code `00`, (2) repository transforms convert other values to `00`, or (3) joins/coercions create `00` indirectly (for example via string parsing or missing-value replacement).

## Data Contracts, Inputs, and Dependencies

Primary input artifact is `2_processed_data/CBP_all.rds`, which must contain at least `year`, `state`, `county`, and one or more NAICS-related fields (`naics`, `NAICS2007.1`, `NAICS2012.1`, `NAICS2017.1` where available). Primary code dependency is `1_code/1_0_ingest/census_CBP.R`; additional dependencies include any script that reads CBP raw pulls and writes `CBP_all.rds` or derived CBP objects. All work should stay in R and repository-local files. No network calls are needed for this diagnostic unless explicitly approved.

## Plan of Work

First, map the end-to-end lineage from CBP pull to `2_processed_data/CBP_all.rds` by identifying which script writes this file and where `naics` is created, renamed, cast, or filtered. Second, insert a compact diagnostic routine in the relevant script or a dedicated scratch diagnostic script under `1_code/` that computes counts of `naics == "00"`, missing `naics`, and top NAICS values by year/state slice at each stage. Third, compare pre-transform and post-transform stage outputs to identify the first appearance of `00`. Finally, record the finding in this ExecPlan, including whether the behavior is source-consistent or code-induced.

## Concrete Steps

All commands should be run from repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1. Locate all CBP pipeline scripts and writes to `CBP_all.rds`.
2. Read the relevant scripts and annotate where NAICS fields are formed.
3. Add or run a diagnostic that reports `naics == "00"` counts before and after each NAICS transformation.
4. Execute the diagnostic script locally and capture short evidence snippets in this plan.

Expected diagnostic excerpt (example structure):

    stage=raw_pull year=2016 n_total=... n_naics00=...
    stage=after_clean year=2016 n_total=... n_naics00=...
    stage=final_cbp_all year=2016 n_total=... n_naics00=...

## Validation and Acceptance

Acceptance is reached when all of the following are true:

1. The first pipeline stage containing `naics == "00"` is identified by name and file path.
2. A reproducible command exists that regenerates the same diagnostic counts.
3. The plan records whether `00` originates from source data or from a repository transformation step.
4. Findings include at least one year-level sanity check showing the transition (or absence of transition) across stages.

## Idempotence and Recovery

Diagnostic commands and script additions should be idempotent: rerunning them must reproduce the same counts without deleting or overwriting canonical outputs. If a diagnostic write is needed, direct it to a clearly marked TEMP/TEST path and document the path in this plan.

## Artifacts and Notes

Key files expected for this investigation:

    1_code/1_0_ingest/census_CBP.R
    2_processed_data/CBP_all.rds
    agent-docs/execplans/2026_02_08_cbp_plan_NAICS_explore.md

Plan created on 2026-02-08 to scope root-cause diagnosis for `naics == "00"` in the CBP processed artifact.
