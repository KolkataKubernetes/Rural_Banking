# Build BFS-CBP-SBA Decomposition Workbook Spec (2026-02-08)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a contributor can render `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` into a single HTML workbook that (1) replicates the two baseline BFS “average state” lollipop descriptives (all counties and rural-only), (2) produces parallel CBP establishment descriptives using the same grouping logic and rural split, and (3) adds an interactive Wisconsin CBP sector-composition pie chart using 2-digit NAICS labels from `0_inputs/naics_2digit_sectors_2007_2012_2017.csv` over 2005–2024. The same workbook will set up a clearly defined, reproducible starting point for the follow-on SBA vs CBP sensitivity section.

This document is an initial spec draft based on `agent-docs/agent_context/2026_02_08_bizformation_SBA.md` and the current workbook scaffold. Open analytical choices for the SBA prediction section are preserved as decision requests.

## Progress

- [x] (2026-02-08 23:18Z) Read `agent-docs/agent_context/2026_02_08_bizformation_SBA.md` and extracted required chunk targets and intended outputs.
- [x] (2026-02-08 23:18Z) Inspected `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` and confirmed the chunk scaffold: `config`, `bfs_lollipop_bizapp_all`, `bfs_lollipop_bizapp_rural`, `cbp_lollipop_bizapp_all`, `cbp_lollipop_bizapp_rural`, `cbp_piechart_wi_agg`.
- [x] (2026-02-08 23:18Z) Reviewed precedent BFS logic in `1_code/1_2_visualize/scratch/bfs_explore.qmd` for category definitions and average-state aggregation semantics.
- [x] (2026-02-08 23:18Z) Inspected key local inputs for data contracts: `2_processed_data/BFS_county.rds`, `2_processed_data/CBP_all.rds`, `0_inputs/naics_2digit_sectors_2007_2012_2017.csv`, and staged SBA FOIA files under `0_inputs/SBA/`.
- [x] (2026-02-08 23:18Z) Drafted this spec plan in `agent-docs/execplans/2026_02_08_sba_bfs_cbp_specplan.md`.
- [x] (2026-02-08 23:18Z) Resolved scope decisions with user: use exact `bfs_explore.qmd` grouping scheme, use year-aware NAICS description mapping, ignore non-chunk markdown asks below section contribution heading for now, and defer all SBA pulls/analysis.
- [ ] Implement workbook chunks and validate render/output behavior.

## Surprises & Discoveries

- Observation: The target workbook currently includes only BFS/CBP chunk scaffolding and one sector pie chunk; SBA analysis chunks are not yet scaffolded in the file.
  Evidence: `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` currently ends at `cbp_piechart_wi_agg`.
- Observation: `CBP_all.rds` includes multiple NAICS-era columns (`NAICS2007.1`, `NAICS2012.1`, `NAICS2017.1`) plus a `naics` field, so two-digit extraction and year-aware label mapping must be explicit.
  Evidence: `CBP_all.rds` columns are `ESTAB|EMP|PAYANN|naics|NAICS2007.1|state|county|year|NAICS2012.1|NAICS2017.1|county_fips|RUCC_2023|rurality`.
- Observation: Local SBA files are already staged and include county/state/approval/year/NAICS fields that can be harmonized without network calls.
  Evidence: `0_inputs/SBA/7_A/*.csv` and `0_inputs/SBA/504/*.csv` contain `ProjectCounty`, `ProjectState`, `ApprovalDate`/`ApprovalFY`, `GrossApproval`, `NAICSCode`/`NaicsCode`.
- Observation: The immediate, concrete asks currently map only to chunk-referenced BFS/CBP visuals; the markdown sections beginning at “Section contribution analysis” are still in-progress user notes.
  Evidence: User explicitly directed to ignore non-chunk markdown asks for this pass and defer SBA.

## Decision Log

- Decision: Scope this first implementation pass to chunks explicitly present in `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd`, while designing SBA integration requirements in the plan for the next pass.
  Rationale: The context note requests SBA analysis, but workbook chunk scaffolding presently defines BFS/CBP replication and CBP sector pie as immediate deliverables.
  Date/Author: 2026-02-08 / Codex
- Decision: Reuse group definitions from `bfs_explore.qmd` (`Wisconsin`, `Midwest excl WI`, `National excl CA/MA/NY`, plus national reference handling) for BFS and CBP comparability.
  Rationale: User explicitly requested replication of prior BFS pattern framing and this preserves interpretability across data sources.
  Date/Author: 2026-02-08 / Codex
- Decision: Keep all work fully local and repository-relative; no network calls or external fetches.
  Rationale: AGENTS.md and task context explicitly require local staged inputs for SBA and related data.
  Date/Author: 2026-02-08 / Codex
- Decision: For this implementation pass, follow the exact grouping implementation already used in `1_code/1_2_visualize/scratch/bfs_explore.qmd` without introducing alternative grouping sets.
  Rationale: User requested exact grouping parity with precedent workbook.
  Date/Author: 2026-02-08 / Codex
- Decision: NAICS labels for CBP pie chart must use one description column selected via year-aware NAICS mapping logic.
  Rationale: User specified a single final description field with mapping keyed by NAICS vintage year.
  Date/Author: 2026-02-08 / Codex
- Decision: Defer SBA integration and any asks from “Section contribution analysis” onward until user provides further concrete chunk-scoped instructions.
  Rationale: User explicitly limited scope to concrete asks already tied to existing chunks.
  Date/Author: 2026-02-08 / Codex

## Outcomes & Retrospective

Initial drafting milestone complete. The new workbook objective is converted into an executable specification tied to the existing chunk scaffold and local data contracts. Scope is now explicitly narrowed to chunk-referenced BFS/CBP visuals and CBP sector pie implementation; SBA and later markdown sections are intentionally deferred.

## Context and Orientation

Target workbook: `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd`.

Relevant precedent and context files:

- `agent-docs/agent_context/2026_02_08_bizformation_SBA.md`
- `1_code/1_2_visualize/scratch/bfs_explore.qmd`
- `2_processed_data/BFS_county.rds`
- `2_processed_data/CBP_all.rds`
- `0_inputs/naics_2digit_sectors_2007_2012_2017.csv`
- `0_inputs/SBA/7_A/*.csv`
- `0_inputs/SBA/504/*.csv`

Current chunk map in workbook:

1. `config`: data loads and helper definitions.
2. `bfs_lollipop_bizapp_all`: replicate BFS average-state lollipop across comparison groups.
3. `bfs_lollipop_bizapp_rural`: replicate BFS average-state lollipop for rural-only subset.
4. `cbp_lollipop_bizapp_all`: CBP establishment analog of the all-county BFS lollipop.
5. `cbp_lollipop_bizapp_rural`: CBP establishment analog of the rural BFS lollipop.
6. `cbp_piechart_wi_agg`: interactive Wisconsin pie chart of CBP establishments by 2-digit NAICS, 2005–2024, using one year-aware NAICS description field.

Plain-language term definitions used in this plan:

- Average-state lollipop: sum metric within each state over the selected period, then average those state totals within each comparison group.
- Rural-only: rows where the existing `rurality` field equals `"rural"`.
- 2-digit NAICS sector: first two digits of the NAICS code, matched to a human-readable description via `0_inputs/naics_2digit_sectors_2007_2012_2017.csv` using the appropriate NAICS vintage year mapping.

## Data Contracts, Inputs, and Dependencies

Dependencies (R): `tidyverse`, `plotly`, and `readr`/`readxl` if needed for auxiliary inputs.

Input contracts:

- `2_processed_data/BFS_county.rds`: must include `state_fips`, `year`, `business_app`, and `rurality`.
- `2_processed_data/CBP_all.rds`: must include `state`, `year`, `ESTAB`, `rurality`, and NAICS vintage fields needed for year-aware mapping (`NAICS2007.1`, `NAICS2012.1`, `NAICS2017.1` and/or consistent equivalents).
- `0_inputs/naics_2digit_sectors_2007_2012_2017.csv`: columns `year`, `naics_2digit`, `description` used to create one final description field after year-aware matching.

Output contracts:

- Rendered HTML workbook from `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` with embedded resources.
- No separate figure export paths unless explicitly requested.

Invariants:

- BFS and CBP comparison-group definitions must match exactly within this workbook.
- CBP rural/all splits must use the same `rurality` semantics as BFS chunks for comparability.
- Wisconsin must be included explicitly as its own category in all comparison plots.
- Grouping definitions in this workbook must match `1_code/1_2_visualize/scratch/bfs_explore.qmd` exactly.

## Plan of Work

First, implement a shared config chunk that loads BFS and CBP data, standardizes state FIPS formatting, and reproduces the exact comparison-group construction used in `1_code/1_2_visualize/scratch/bfs_explore.qmd`. Centralize helper functions for average-state aggregation so BFS and CBP chunks call the same logic.

Second, implement `bfs_lollipop_bizapp_all` and `bfs_lollipop_bizapp_rural` as direct replications of precedent semantics from `bfs_explore.qmd`: aggregate `business_app` by state over the full available period in the data object, then average state totals within each group; for rural chunk, filter to `rurality == "rural"` before aggregation.

Third, implement CBP analog chunks (`cbp_lollipop_bizapp_all`, `cbp_lollipop_bizapp_rural`) using `ESTAB` as the numerator with the same grouping and averaging logic, including a consistent subtitle that clarifies the metric switch from business applications (BFS) to establishments (CBP).

Fourth, implement `cbp_piechart_wi_agg` as an interactive Plotly pie chart for Wisconsin only, summing `ESTAB` from 2005 to 2024 by 2-digit NAICS sector. Build a year-aware NAICS mapping helper that uses the appropriate NAICS vintage year when matching to `0_inputs/naics_2digit_sectors_2007_2012_2017.csv`, then materialize one final description column used in the pie chart.

Fifth, stop at the chunk-scoped outputs above for this pass. Do not add SBA pulls or implement sections beginning at “Section contribution analysis” until the user provides concrete chunk-scoped instructions for that phase.

## Concrete Steps

Run from repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1. Edit `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` and populate `config`, `bfs_lollipop_bizapp_all`, `bfs_lollipop_bizapp_rural`, `cbp_lollipop_bizapp_all`, `cbp_lollipop_bizapp_rural`, and `cbp_piechart_wi_agg`.
2. Keep transformations helper-driven in `config` so chunk logic remains concise and consistent.
3. Render workbook:

    quarto render 1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd

4. Verify rendered charts appear and interactive pie behaves in the HTML.

Expected short transcript excerpt:

    processing file: 2026_02_08_sba_bfs_cbp.qmd
    output file: 2026_02_08_sba_bfs_cbp.html

## Validation and Acceptance

Acceptance criteria:

1. `quarto render 1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` completes without error.
2. BFS all/rural lollipop chunks reproduce the intended average-state comparison pattern framing from `bfs_explore.qmd`.
3. CBP all/rural lollipop chunks run with identical grouping logic and clearly represent `ESTAB` (not `business_app`).
4. Wisconsin CBP pie chart is interactive and displays 2-digit NAICS sector labels from the NAICS lookup file for 2005–2024 summed establishments.

Sanity checks:

- Confirm no missing `state_fips`/group labels after BFS and CBP aggregation.
- Spot-check one sector in the pie chart by manually verifying summed `ESTAB` from raw filtered Wisconsin CBP rows.
- Confirm rural chunk filters reduce to rows where `rurality == "rural"` and no non-rural rows remain.

## Idempotence and Recovery

Rendering is idempotent given unchanged local inputs. Re-running `quarto render` should regenerate the same workbook outputs.

If a chunk fails due to schema mismatches, update only the helper logic in `config` and rerender; avoid ad hoc fixes duplicated across chunks.

No destructive file operations are required.

## Artifacts and Notes

Primary files:

- `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd`
- `1_code/1_2_visualize/scratch/bfs_explore.qmd`
- `agent-docs/agent_context/2026_02_08_bizformation_SBA.md`
- `agent-docs/execplans/2026_02_08_sba_bfs_cbp_specplan.md`

## Decision Requests

All current decision requests are resolved for this pass. Add new requests here only if implementation uncovers ambiguity inside the currently scoped chunks.

Plan created on 2026-02-08 from `agent-docs/agent_context/2026_02_08_bizformation_SBA.md` and existing workbook scaffolding, then updated on 2026-02-08 with user decisions to lock exact `bfs_explore.qmd` groupings, enforce year-aware single-column NAICS descriptions, and defer all non-chunk-scoped SBA/section-contribution asks.
