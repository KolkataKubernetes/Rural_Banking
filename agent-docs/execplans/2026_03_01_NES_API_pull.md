# Build Staged NES 2010-2023 Pull (Wisconsin Then National) in census_NES.r

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a user will be able to run a new script at `1_code/1_0_ingest/census_NES.r` to first confirm a Wisconsin-only pull for all years 2010-2023 and then run a national pull for the same year range. The script will harmonize yearly NAICS variable names into one `naics` column and save one reproducible national output for downstream analysis. The user-visible result is a staged and debuggable workflow: Wisconsin validation first, then full national ingest.

## Progress

- [x] (2026-03-01 00:00Z) Read task context in `agent-docs/agent_context/2026_03_01_nes_apicall.md` and extracted requested deliverable: create a spec for a new `census_NES.r` script modeled on `census_CBP.r`.
- [x] (2026-03-01 00:00Z) Reviewed `1_code/1_0_ingest/census_CBP.r` structure and helper patterns to mirror setup, API helper design, NAICS-year logic, RUCC join pattern, and save behavior.
- [x] (2026-03-01 00:00Z) Confirmed NES API endpoint details from the specified Census developer page (`/data/{year}/nonemp`, example query with `NAICS2023`).
- [x] (2026-03-01 00:00Z) Authored this execution-ready spec plan in `agent-docs/execplans/2026_03_01_NES_API_pull.md`.
- [x] (2026-03-01 00:00Z) Implemented Milestone 1 code in `1_code/1_0_ingest/census_NES.r` (Wisconsin-only all-year pull logic, NES helper functions, and `NES_all.rds` output path).
- [x] (2026-03-01 00:00Z) Resolved Milestone 1 `HTTP 400 unknown variable 'NAME'` failure by mirroring CBP multi-year variable logic: fixed `vars_common` + detected NAICS field, with no `NAME` in the all-year request.
- [x] (2026-03-01 00:00Z) Implemented Milestone 2 national expansion in `1_code/1_0_ingest/census_NES.r` by replacing the single-state loop with `state_fips.csv`-driven state iteration while preserving year and NAICS logic.
- [ ] Run Milestone 1 API pull and validate Wisconsin-only output (`state == "55"`, years 2010-2023).
- [ ] Run validation pull and confirm `2_processed_data/NES_all.rds` schema and national coverage, with Wisconsin still present.

## Surprises & Discoveries

- Observation: The requested NES task is framed as "same structure as `census_CBP.r`" and not as a rewrite of existing CBP ingestion.
  Evidence: `agent-docs/agent_context/2026_03_01_nes_apicall.md` asks to create a new script named `census_NES.r` using `census_CBP.r` as the structural template.

- Observation: Current `census_CBP.r` is no longer Wisconsin-only; it loops all states from `0_inputs/state_fips.csv` before writing `CBP_all.rds`.
  Evidence: `states <- c(state_fips$FIPS_CODE)` followed by nested `map_dfr(states, map_dfr(years, ...))`.

- Observation: NES 2023 API example uses `NAICS2023` as filter variable and endpoint `/nonemp` rather than `/cbp`.
  Evidence: Census NES API page lists example `api.census.gov/data/2023/nonemp?get=NRCPTOT,NAME&for=county:*&in=state:06&NAICS2023=54`.

- Observation: NES multi-year pull failed at year index 1 with `HTTP 400 error: unknown variable 'NAME'` when `NAME` was included in all-year requests.
  Evidence: `Rscript 1_code/1_0_ingest/census_NES.r` failed inside `map_dfr()` -> `nes_get()` with Census API response `unknown variable 'NAME'`.

## Decision Log

- Decision: Create a separate script `1_code/1_0_ingest/census_NES.r` rather than modifying `census_CBP.r`.
  Rationale: The task explicitly requests a new script for NES and preserving CBP logic avoids cross-source regression risk.
  Date/Author: 2026-03-01 / Codex

- Decision: Use a staged geography approach: Milestone 1 Wisconsin-only for all years, then Milestone 2 national for all years.
  Rationale: Wisconsin-first execution de-risks variable and NAICS handling before scaling to all states.
  Date/Author: 2026-03-01 / Codex

- Decision: Harmonize year-specific NAICS fields (for example `NAICS2023`, `NAICS2017`, `NAICS2012`, `NAICS2007`, or `NAICS`) into a single output column `naics`.
  Rationale: Downstream joins and summaries should not depend on changing Census variable names across years.
  Date/Author: 2026-03-01 / Codex

- Decision: Write a dedicated NES output file `2_processed_data/NES_all.rds`.
  Rationale: Keeps NES artifacts isolated from CBP artifacts and makes reruns idempotent.
  Date/Author: 2026-03-01 / Codex

- Decision: Mirror CBP multi-year variable pull behavior by excluding `NAME` from all-year NES requests and using `vars_common <- c("NESTAB", "NRCPTOT")` plus `naics_var`.
  Rationale: CBP already avoids `NAME` in multi-year pulls for cross-year compatibility; applying the same pattern resolves the NES `unknown variable 'NAME'` failure at early years.
  Date/Author: 2026-03-01 / Codex

- Decision: Source the hard-coded `naics_2digit` sector list from Census NAICS guidance (`https://www.census.gov/programs-surveys/economic-census/year/2022/guidance/understanding-naics.html`) and include `00` as the all-industries aggregate code.
  Rationale: This keeps sector selection tied to a documented Census reference rather than ad hoc code choices, while preserving compatibility with the existing CBP sector loop pattern.
  Date/Author: 2026-03-01 / Codex

## Outcomes & Retrospective

Milestone 1 and Milestone 2 code implementation are complete in `1_code/1_0_ingest/census_NES.r`, including NES-specific helper functions, cross-year-compatible variable selection, and national state iteration driven by `0_inputs/state_fips.csv`. During execution testing, a cross-year variable compatibility issue was identified (`NAME` not supported in at least one early-year NES request). The script was updated to mirror CBP variable-pull logic for all-year runs (`vars_common` + detected NAICS field, no `NAME`), which resolves the identified failure mode. Full API-backed validation remains pending.

## Context and Orientation

The repository currently has a working Census ingestion pattern in `1_code/1_0_ingest/census_CBP.r`. That script defines (1) package loading, (2) API key loading from `0_inputs/census_apikey.md`, (3) a reusable API fetch helper (`cbp_get()`), (4) a variable-discovery helper (`cbp_list_vars()`), (5) multi-year pull logic, (6) optional RUCC rurality classification using `0_inputs/Ruralurbancontinuumcodes2023.xlsx`, and (7) an `.rds` export to `2_processed_data`.

This plan adds a sibling script `1_code/1_0_ingest/census_NES.r` with parallel structure but NES-specific endpoints and variables. "NES" means Nonemployer Statistics: annual Census data for businesses with no paid employees. In the API, NES is exposed at `https://api.census.gov/data/{year}/nonemp`. The request format is the standard Census pattern with `get=`, `for=`, `in=`, optional NAICS filter, and optional API key.

Key files for this task:
- `1_code/1_0_ingest/census_CBP.r` (template behavior to mirror).
- `1_code/1_0_ingest/census_NES.r` (new script to create).
- `0_inputs/census_apikey.md` (optional key source).
- `0_inputs/Ruralurbancontinuumcodes2023.xlsx` (if RUCC classification is retained in NES output).
- `2_processed_data/NES_all.rds` (new output artifact).
- `agent-docs/agent_context/2026_03_01_nes_apicall.md` (task context).

## Milestones

### Milestone 1: Create NES helper functions and complete Wisconsin pull for all years

At the end of this milestone, `1_code/1_0_ingest/census_NES.r` exists with setup, `load_census_key()`, `nes_get()`, and `nes_list_vars()`, and produces a Wisconsin-only multi-year pull (`state = "55"`) for 2010-2023. This milestone should confirm year coverage and NAICS normalization on a smaller geography before national scaling.

### Milestone 2: Expand the same all-year pull to national coverage

At the end of this milestone, the script loops years 2010-2023 for all states from `0_inputs/state_fips.csv`, resolves the available NAICS variable by year, normalizes that field into `naics`, appends `year`, and produces one combined national in-memory object `out`.

### Milestone 3: Persist output and validate reproducibility

At the end of this milestone, the script writes `2_processed_data/NES_all.rds`, reruns cleanly, and passes acceptance checks for year range, geography, and expected columns.

## Plan of Work

Create `1_code/1_0_ingest/census_NES.r` by copying the organization of `census_CBP.r` and then replacing CBP-specific elements with NES equivalents. Keep the package stack the same unless implementation proves a package is unused. Keep pathing repository-relative and do not hardcode user-specific paths.

In the helper section, define `nes_get()` with arguments parallel to `cbp_get()` (`year`, `vars`, `state`, `county`, `naics`, `naics_var`, optional key). Set the base URL to `https://api.census.gov/data/{year}/nonemp`. Preserve the robust response handling pattern from CBP: return empty typed tibble for HTTP 204, include response body in non-200 stop messages, and parse numeric fields with `parse_number` for measure columns.

Add `nes_list_vars(year)` using `.../nonemp/variables.json` to support dynamic variable checks each year. After helper definitions, include an example call for Wisconsin 2023 to verify wiring, then proceed into multi-year pull logic.

Implement Milestone 1 in the multi-year section by setting `years <- 2010:2023`, `state <- "55"`, and `county <- "*"`. Define a conservative shared measure set centered on NES counts/receipts variables that exist across the full range (finalize via `nes_list_vars()` checks during implementation). Use the hard-coded `naics_2digit` pull list sourced from Census NAICS guidance (`https://www.census.gov/programs-surveys/economic-census/year/2022/guidance/understanding-naics.html`) and retain `00` as the all-industries aggregate. For each year, inspect available variable names, detect the highest-priority NAICS field from `NAICS2023`, `NAICS2017`, `NAICS2012`, `NAICS2007`, `NAICS`, request that year with `nes_get()`, rename detected NAICS column to `naics`, and add `year`.

Implement Milestone 2 by generalizing geography from one state to all states using `0_inputs/state_fips.csv` (matching the CBP pattern). Replace the single-state loop with a nested state-year loop so the national object preserves the same schema already validated in Milestone 1. Keep NAICS harmonization logic identical between milestones; only geography scope should change.

Retain the RUCC join only if needed by current Wisconsin downstream scripts; if retained, mirror the CBP join pattern and keep both raw RUCC code and derived `rurality`. If RUCC is not required for NES outputs, skip it and document that decision in both script comments and this plan's Decision Log when implementation begins.

Finish by writing `saveRDS(out, file.path("2_processed_data", "NES_all.rds"))`. Do not overwrite other canonical outputs. Document this new artifact in implementation notes and README only if later explicitly requested.

## Concrete Steps

Run all commands from repository root:
`/Users/indermajumdar/Research/Rural_Banking`

1. Create the new script from the CBP pattern.

    cp 1_code/1_0_ingest/census_CBP.r 1_code/1_0_ingest/census_NES.r

2. Implement Milestone 1 code only in `1_code/1_0_ingest/census_NES.r`.

   Required edit blocks:
   - Update header metadata and purpose text to NES.
   - Rename helper functions `cbp_get` -> `nes_get` and `cbp_list_vars` -> `nes_list_vars`.
   - Replace endpoint paths `/cbp` with `/nonemp` and `/cbp/variables.json` with `/nonemp/variables.json`.
   - Replace variable defaults with NES-appropriate defaults verified via `nes_list_vars()`.
   - Implement Milestone 1 as Wisconsin-only (`state = "55"`, years 2010-2023).
   - Rename output path to `2_processed_data/NES_all.rds`.

3. Run Milestone 1 (Wisconsin-only) and verify the checkpoint.

    Rscript 1_code/1_0_ingest/census_NES.r

   Expected short transcript excerpt for Milestone 1:

    Pulling NES data for year 2010, state 55
    Pulling NES data for year 2011, state 55
    ...
    Pulling NES data for year 2023, state 55

4. Validate Milestone 1 output.

    Rscript -e "x <- readRDS(file.path('2_processed_data','NES_all.rds')); print(range(x$year, na.rm=TRUE)); print(length(unique(x$state))); print(unique(x$state)); print(colnames(x))"

   Expected excerpt for Milestone 1:

    [1] 2010 2023
    [1] 1
    [1] "55"
    [1] "..." "naics" "year" ...

5. Edit `1_code/1_0_ingest/census_NES.r` to implement Milestone 2 by expanding geography to all states.

   Required edit block:
   - Replace Wisconsin-only state assignment with a state loop using `0_inputs/state_fips.csv`, while preserving the same year and NAICS logic from Milestone 1.

6. Run Milestone 2 (national) and verify final output.

    Rscript 1_code/1_0_ingest/census_NES.r

   Expected short transcript excerpt for Milestone 2:

    Pulling NES data for year 2010, state 01
    ...
    Pulling NES data for year 2023, state 56

7. Validate final national output.

    Rscript -e "x <- readRDS(file.path('2_processed_data','NES_all.rds')); print(range(x$year, na.rm=TRUE)); print(length(unique(x$state))); print('55' %in% unique(x$state)); print(colnames(x))"

   Expected excerpt for Milestone 2:

    [1] 2010 2023
    [1] 50
    [1] TRUE
    [1] "..." "naics" "year" ...

## Validation and Acceptance

Acceptance criteria are behavioral and must all pass:

- Script run: `Rscript 1_code/1_0_ingest/census_NES.r` completes without error.
- Artifact exists: `2_processed_data/NES_all.rds` is created.
- Geography check (Milestone 1): Wisconsin pull has all records with `state == "55"` and full years 2010-2023.
- Geography check (Milestone 2): national pull has multiple state FIPS values and includes Wisconsin (`"55"` present).
- Year coverage check: minimum year is 2010 and maximum year is 2023.
- Schema check: output includes at least one NES receipt or establishment measure, plus `naics` and `year`.
- NAICS normalization check: output has one standardized `naics` column and does not rely on mixed year-specific NAICS columns for downstream use.

Suggested sanity checks after load:
- `nrow(x) > 0`
- `length(unique(x$year)) == 14`
- `length(unique(x$state)) > 1`
- `"55" %in% unique(x$state)`
- `sum(is.na(x$naics))` reviewed and explained if non-zero

## Idempotence and Recovery

This workflow is designed to be rerunnable. Re-running `census_NES.r` should recreate `NES_all.rds` deterministically given the same API responses and script version. If a specific year fails due to variable mismatch, first inspect `nes_list_vars(year)` and adjust the year's variable selection logic without changing downstream schema (`naics`, `year`, and measure columns). If API throttling or transient network errors occur, rerun the script; no manual cleanup is required beyond replacing `NES_all.rds` with the fresh run output.

If a failed run leaves a partial object in memory, restart the R session and rerun the script from the top to ensure a clean state.

## Artifacts and Notes

Primary artifact produced by implementation:

    2_processed_data/NES_all.rds

Primary code artifact:

    1_code/1_0_ingest/census_NES.r

No other output files should be created in this task unless explicitly requested.

## Data Contracts, Inputs, and Dependencies

Dependencies:
- R packages: `httr2`, `jsonlite`, `dplyr`, `purrr`, `readr` (and `readxl` only if RUCC join is retained).
- External API: Census NES endpoint `https://api.census.gov/data/{year}/nonemp` for years 2010-2023.
- Optional credential file: `0_inputs/census_apikey.md` for API key injection.

`nes_get()` contract:
- Required inputs: `year` (numeric/integer), `vars` (character vector of API variables), `state` (2-digit FIPS string), `county` ("*" or 3-digit FIPS), optional `naics` and `naics_var`.
- Output: tibble containing requested variables plus Census geography columns (`state`, `county`) and any added normalization columns (`naics`, `year`) after post-processing.
- Invariants: each returned row corresponds to one Census geography and industry slice for that year; `year` is present after multi-year binding; output can be row-bound across all years.

`nes_list_vars()` contract:
- Required input: `year`.
- Output: tibble with variable names and labels from Census `variables.json` used to verify requested fields before pull.
- Side effect: none (read-only API call).

Script-level input/output contract:
- Inputs: API responses for each year in 2010-2023, optional `census_apikey.md`, optional RUCC Excel file.
- Output: `2_processed_data/NES_all.rds` with national NES observations across requested years and stable schema for downstream use.
- Observable invariants: full requested year span, standardized NAICS identifier column, multi-state coverage with Wisconsin included.

NAICS sector-list contract:
- The script defines a fixed `naics_2digit` request list based on Census NAICS guidance at `https://www.census.gov/programs-surveys/economic-census/year/2022/guidance/understanding-naics.html`.
- `00` is intentionally included as the all-industries aggregate pull in addition to explicit 2-digit sectors.
- Some requested sectors may return no rows for specific year/state slices; this is an API data-result outcome, not a change in requested sector scope.

## Change Notes

- 2026-03-01: Initial ExecPlan created to specify a new `census_NES.r` ingestion script modeled on existing `census_CBP.r`, based on `agent-docs/agent_context/2026_03_01_nes_apicall.md` and NES API endpoint details from the Census NES developer page.
- 2026-03-01: Revised milestone scope per user request: Milestone 1 now covers Wisconsin for all years, and Milestone 2 now expands to national coverage for all years.
- 2026-03-01: Updated progress after implementing Milestone 1 code in `1_code/1_0_ingest/census_NES.r`; API-run validation deferred.
- 2026-03-01: Documented and resolved Milestone 1 `unknown variable 'NAME'` error by aligning NES multi-year variable selection to CBP-style `vars_common + naics_var` logic.
- 2026-03-01: Documented the source for the hard-coded `naics_2digit` list as Census NAICS guidance (`understanding-naics.html`) and clarified that `00` is the all-industries aggregate code.
- 2026-03-01: Implemented Milestone 2 code by replacing Wisconsin-only iteration with national state iteration from `0_inputs/state_fips.csv` while preserving Milestone 1 year/NAICS logic.
