# Complete Wisconsin Rural Business-Growth Indicator Workbook (BFS, CBP, NES)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a contributor can render `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd` into an HTML workbook that reproduces the established Wisconsin-vs-peer lollipop comparisons for BFS and CBP, adds a CBP per-1-million normalization, and adds equivalent rural-only NES lollipops (raw and per-1-million). This gives one reproducible, transparent workbook for extension-facing discussion of rural Wisconsin business growth patterns across employer and nonemployer sources.

The user-visible result is a rendered workbook containing five completed rural-only figure chunks: `lollipop_bfs`, `lollipop_cbp`, `lollipop_cbp_1mill`, `lollipop_nes`, and `lollipop_nes_1mill`, with all preprocessing logic centralized in `config` and commented for traceability.

## Progress

- [x] (2026-03-02 18:20Z) Read `agent-docs/agent_context/2026_03_01_rural_WI_bizgrowth_windicator_explore.md` and extracted required deliverables.
- [x] (2026-03-02 18:21Z) Reviewed `agent-docs/PLANS.md` and `agent-docs/ExecPlan_TEMPLATE.md` for ExecPlan structure requirements.
- [x] (2026-03-02 18:22Z) Inspected current target workbook scaffold in `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd`.
- [x] (2026-03-02 18:23Z) Confirmed referenced precedent workbook exists at `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` and NES ingest script exists at `1_code/1_0_ingest/census_NES.r`.
- [x] (2026-03-02 18:24Z) Drafted this spec plan in `agent-docs/execplans/2026_03_02_rural_WI_bizgrowth_windicator_specplan.md`.
- [x] (2026-03-02 18:31Z) Resolved user decisions: all lollipops should be rural-only using prior county-level rurality definition; NES metric is `NESTAB`.
- [x] (2026-03-02 18:29Z) Implemented workbook edits in `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd`, including helper functions, RUCC-derived NES rurality assignment, and all five lollipop chunks.
- [x] (2026-03-02 18:29Z) Rendered and validated workbook output at `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.html`.
- [x] (2026-03-02 18:38Z) Added temporary QA section (`## QA Section (Delete later)`) with chunk `qa_unmatched_rucc_codes` to compare unmatched RUCC county-code sets across BFS, CBP, and NES.
- [x] (2026-03-02 18:39Z) Extended QA comparison output with overlap-count column (`jointly_matched_unmatched_codes`) and re-rendered successfully.
- [ ] Before closing this spec plan, edit `1_code/1_0_ingest/census_NES.r` to create `rurality` during NES API ingest (county FIPS RUCC join, same RUCC 1-3 metro rule as BFS/CBP), then regenerate `2_processed_data/NES_all.rds`.

## Surprises & Discoveries

- Observation: The target workbook currently includes `config`, `lollipop_bfs`, `lollipop_cbp`, and `lollipop_cbp_1mill`, but does not yet include the two NES chunk stubs requested in context (`lollipop_nes`, `lollipop_nes_1mill`).
  Evidence: `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd` ends after the “Does the pattern hold using nonemployer statistics?” heading.
- Observation: The local R runtime failed when attempting direct RDS inspection due a missing `libreadline.6.2.dylib` dependency in this shell environment.
  Evidence: `Rscript` exits with dyld error referencing `/Users/indermajumdar/opt/anaconda3/lib/R/lib/libR.dylib`.
- Observation: `NES_all.rds` has county rows that do not match RUCC FIPS and therefore receive `NA` in `RUCC_2023`.
  Evidence: Validation check found `NES missing RUCC: 2103` rows after `county_fips` join.
- Observation: Unmatched RUCC county-code sets are not identical across BFS, CBP, and NES; overlap diagnostics are needed for transparent reconciliation.
  Evidence: Added QA chunk `qa_unmatched_rucc_codes` to output per-dataset unmatched counts, pairwise equality flags, pairwise overlap counts, and left/right set differences.

## Decision Log

- Decision: Scope this plan strictly to completing the existing workbook (`1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd`) and not refactor ingestion scripts or upstream processed data.
  Rationale: User request is explicitly to produce a spec plan for the listed workbook tasks; AGENTS.md prioritizes scope control and reproducibility.
  Date/Author: 2026-03-02 / Codex
- Decision: Reuse grouping definitions and average-state lollipop semantics from `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` to preserve comparability with prior project outputs.
  Rationale: User explicitly requested reproducing prior lollipop logic in referenced chunks.
  Date/Author: 2026-03-02 / Codex
- Decision: Treat NES lollipop measure as `NESTAB` (nonemployer establishments) unless user requests `NRCPTOT` instead.
  Rationale: Task asks for a lollipop like CBP establishment chart; `NESTAB` is the direct analog.
  Date/Author: 2026-03-02 / Codex
- Decision: Implement all lollipops as rural-only and use the existing county-level rurality definition already used in prior project work.
  Rationale: User explicitly confirmed rural-only scope and requested consistency with previously used county-level rural-metro definitions.
  Date/Author: 2026-03-02 / Codex
- Decision: Add a temporary workbook QA section to compare unmatched RUCC county-code sets across BFS, CBP, and NES before final cleanup.
  Rationale: User requested explicit confirmation of whether non-matching codes are the same across datasets, and requested an overlap-count column in the comparison output.
  Date/Author: 2026-03-02 / Codex

## Outcomes & Retrospective

Implementation and validation completed. `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd` now renders all required rural-only lollipop charts for BFS, CBP, CBP-per-million, NES, and NES-per-million, with shared helpers and explicit transformation comments in `config`. A temporary QA section was added to compare unmatched RUCC county-code sets across BFS/CBP/NES, including pairwise overlap counts (`jointly_matched_unmatched_codes`). Render succeeded after these additions with `QUARTO_R=/usr/local/bin/Rscript quarto render 1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd`, producing `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.html`.

## Context and Orientation

Primary target file is `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd`.

Relevant reference files are:

- `agent-docs/agent_context/2026_03_01_rural_WI_bizgrowth_windicator_explore.md` (task requirements).
- `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd` (working precedent for BFS/CBP lollipop and per-million logic).
- `1_code/1_0_ingest/census_NES.r` (upstream NES pull definition and expected NES variable names).
- `2_processed_data/BFS_county.rds`, `2_processed_data/CBP_all.rds`, `2_processed_data/NES_all.rds` (processed inputs).
- `0_inputs/CORI/fips_participation.csv` (state-level participation/population basis for per-million normalization).

Definitions used in this plan:

- Average-state lollipop means: sum a metric within each state over the selected years, then average those state totals within each comparison group.
- Rural-only means rows where `rurality == "rural"`.
- Per-1-million normalization means dividing each state cumulative metric by cumulative state population for matched years and scaling by 1,000,000.
- NES rurality provenance: `1_code/1_0_ingest/census_NES.r` currently saves `2_processed_data/NES_all.rds` without a `rurality` field (schema includes `state`, `county`, `year`, `NESTAB`, `NRCPTOT`, and NAICS columns). For this workbook, `rurality` must be created in `config` by joining county FIPS to `0_inputs/Ruralurbancontinuumcodes2023.xlsx` and applying the same project rule used in `1_code/1_0_ingest/census_BFS.R` and `1_code/1_0_ingest/census_CBP.R`: RUCC codes 1, 2, and 3 are `"metro"`; all other RUCC codes are `"rural"`.

## Data Contracts, Inputs, and Dependencies

Dependencies in the workbook are `tidyverse` and `plotly`.

Input contracts:

- `2_processed_data/BFS_county.rds` must provide at least `state_fips`, `year`, `business_app`, and `rurality`.
- `2_processed_data/CBP_all.rds` must provide at least `state`, `year`, `ESTAB`, and `rurality`.
- `2_processed_data/NES_all.rds` is expected to provide state and county FIPS (`state`, `county`), yearly identifier (`year`), NAICS field (`naics`), and nonemployer establishments metric (`NESTAB`).
- `0_inputs/CORI/fips_participation.csv` must provide state FIPS and year (`FIPS`, `year`) plus participation/force fields needed to derive state population.

Output contracts:

- Rendered workbook at `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.html`.
- No additional output files are required unless explicitly requested.

Invariants:

- BFS and CBP lollipops must match the grouping and aggregation semantics from the February 8 workbook.
- NES lollipops must apply rural-only filtering before aggregation.
- Per-million charts must use the same denominator construction approach across CBP and NES.

## Plan of Work

Update the `config` chunk in `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd` to fully prepare BFS, CBP, participation, and NES objects for all downstream chunks. Keep shared helpers in `config`: grouping assignment, average-state aggregation, and per-million aggregation. Add comments that name which prepared data frame powers each chunk, matching the user’s reproducibility request.

Implement `lollipop_bfs` by reproducing the same logic and category framing as `bfs_lollipop_bizapp_rural` from `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd`. Implement `lollipop_cbp` by reproducing the same logic as `cbp_lollipop_bizapp_rural` from the same precedent file.

Implement `lollipop_cbp_1mill` by reusing CBP grouped/rural data and joining state-year population derived from `fips_participation.csv`, then computing category-level average state values per 1 million population.

Add missing chunks `lollipop_nes` and `lollipop_nes_1mill` under the NES section heading. Build rural-only NES state totals with the same comparison-group mapping, then produce raw and per-million lollipops using `NESTAB`.

Keep output scope strictly to this workbook. Do not add new datasets, do not call external APIs, and do not modify upstream ingest scripts during this task.

Before this spec plan is closed, run one follow-on ingest harmonization task: move NES rurality construction from workbook-level logic into `1_code/1_0_ingest/census_NES.r` so `NES_all.rds` carries `county_fips`, `RUCC_2023`, and `rurality` at write time, matching the BFS/CBP ingest pattern.

## Concrete Steps

Working directory: `/Users/indermajumdar/Research/Rural_Banking`.

1. In `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd`, expand the existing `config` chunk (starts at line 7 in current file) by reusing the same helper blocks already proven in `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd`:
   - Copy and adapt `apply_grouping()` from lines 62-73.
   - Copy and adapt `avg_state_lollipop()` from lines 75-83 (or 108-116; they are duplicates in that file).
   - Copy and adapt `avg_state_lollipop_per_million()` from lines 84-106.
   - Keep `bfs_grouped` and `cbp_grouped` prep pattern from lines 118-125.
   - Add NES prep immediately after `nes <- read_rds(...)`: build `county_fips = paste0(state, county)` with zero-padding, join RUCC from `0_inputs/Ruralurbancontinuumcodes2023.xlsx`, create `rurality` using RUCC 1-3 = `\"metro\"` else `\"rural\"`, then apply `apply_grouping()` to produce `nes_grouped`.
2. Populate chunk `lollipop_bfs` (line 67 in current file) by mirroring `bfs_lollipop_bizapp_rural` from `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd:333`:
   - Filter `bfs_grouped` to `rurality == \"rural\"`.
   - Call `avg_state_lollipop(\"business_app\")`.
   - Reuse the same lollipop `ggplot` structure and category color mapping.
3. Populate chunk `lollipop_cbp` (line 77) by mirroring `cbp_lollipop_bizapp_rural` from `1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd:375`:
   - Filter `cbp_grouped` to `rurality == \"rural\"`.
   - Call `avg_state_lollipop(\"ESTAB\")`.
   - Reuse the same lollipop `ggplot` structure.
4. Populate chunk `lollipop_cbp_1mill` (line 87) using the same prep as step 3 but call `avg_state_lollipop_per_million(\"ESTAB\")` instead of `avg_state_lollipop()`.
5. Under the “Does the pattern hold using nonemployer statistics?” section (after line 95), add two new chunks in this order:
   - `lollipop_nes`: filter `nes_grouped` to `rurality == \"rural\"`, compute `avg_state_lollipop(\"NESTAB\")`, and render the same lollipop geometry.
   - `lollipop_nes_1mill`: same filtered input but compute `avg_state_lollipop_per_million(\"NESTAB\")`, then render the same lollipop geometry.
6. Keep all new comments in `config` explicit about which prepared object feeds which chunk (`bfs_grouped` -> `lollipop_bfs`, `cbp_grouped` -> `lollipop_cbp`/`lollipop_cbp_1mill`, `nes_grouped` -> `lollipop_nes`/`lollipop_nes_1mill`).
7. Render the workbook:

    quarto render 1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd

8. Confirm output exists:

    ls -l 1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.html

Expected short render excerpt:

    processing file: 2026_03_01_windicator_wi_bizgrowth.qmd
    output file: 2026_03_01_windicator_wi_bizgrowth.html

## Validation and Acceptance

Acceptance criteria:

1. Render command completes without errors.
2. `lollipop_bfs` and `lollipop_cbp` visually replicate category logic and ordering from the February 8 workbook precedent.
3. `lollipop_cbp_1mill` is present and uses state population normalization.
4. `lollipop_nes` and `lollipop_nes_1mill` are present, rural-only, and use NES establishments.
5. All transformations needed by each figure are documented with inline comments in `config`.

Sanity checks:

1. Verify Wisconsin category appears in all five charts.
2. Spot-check at least one state: per-million value equals raw cumulative metric divided by cumulative population in matched years times 1,000,000.
3. Verify no non-rural records are included in NES lollipop inputs.

## Idempotence and Recovery

Editing and render steps are idempotent given unchanged inputs. Re-running `quarto render` should overwrite only the workbook HTML output.

If render fails due schema drift in NES columns, recover by adjusting only the NES prep block in `config` (for example, mapping alternate state FIPS column names) and re-rendering. Do not patch source data files.

## Artifacts and Notes

Planned modified file:

- `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd`

Planned output artifact:

- `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.html`

Plan artifact:

- `agent-docs/execplans/2026_03_02_rural_WI_bizgrowth_windicator_specplan.md`

## Decision Requests

- Open implementation follow-up: add RUCC-based `rurality` creation directly in `1_code/1_0_ingest/census_NES.r` before closing this plan, and rerun NES ingest to refresh `2_processed_data/NES_all.rds`.

## Change Notes

- 2026-03-02: Created initial spec plan from `agent-docs/agent_context/2026_03_01_rural_WI_bizgrowth_windicator_explore.md`, anchored to current workbook state and `agent-docs/PLANS.md` requirements.
- 2026-03-02: Updated plan after user confirmation that all lollipops should be rural-only and NES should use `NESTAB`.
- 2026-03-02: Updated living sections after execution to record completed implementation, render validation, and RUCC-join discovery for NES.
- 2026-03-02: Added explicit pre-close follow-up requirement to harmonize NES ingest with BFS/CBP by creating `rurality` in `census_NES.r`.
- 2026-03-02: Added QA-section implementation notes documenting unmatched RUCC set comparison and intersection-count column requested by user.
