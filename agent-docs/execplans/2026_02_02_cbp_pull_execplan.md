# Build Wisconsin CBP 2010–2023 Pull in census_CBP.R

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a user can run `1_code/1_0_ingest/census_CBP.R` and obtain a single in-memory data frame named `wi_all` that stacks Wisconsin County Business Patterns (CBP) county-level data for every year from 2010 through 2023. The data pull will be consistent across years by using a shared set of variables that exist in each year and by annotating the year explicitly. The user can confirm success by running the script and observing that `wi_all` exists, includes a `year` column spanning 2010–2023, and contains only Wisconsin county records.

## Progress

- [x] (2026-02-02 00:00Z) Read `agent-docs/agent_context/2026_02_02_CBP_pull.md` and inspected `1_code/1_0_ingest/census_CBP.R` to understand the dummy script and helper functions.
- [x] (2026-02-02 00:00Z) Refreshed the plan after the user updated `1_code/1_0_ingest/census_CBP.R` to include a 2023 variable listing and a `wi_2023` example pull.
- [x] (2026-02-02 00:00Z) Defined the common variable set and NAICS filter strategy for 2010–2023 (removed `NAME` due to 2010 API support).
- [x] (2026-02-02 00:00Z) Implemented the multi-year pull that builds `wi_all` and added the RUCC join for metro vs rural labels.
- [x] (2026-02-02 00:00Z) Validated the script locally with CBP API access; 2010–2023 pulls completed without error.
- [x] (2026-02-02 00:00Z) Recorded that the user made manual edits to `1_code/1_0_ingest/census_CBP.R` after implementation; revalidation may be required if logic changed.

## Surprises & Discoveries

- Observation: `cbp_get()` only supports the `NAICS2017` query parameter, which may not exist for earlier CBP years.
  Evidence: The function sets `query$NAICS2017 <- naics` unconditionally when `naics` is provided.
- Observation: CBP 2010 rejects the `NAME` variable in `get=...`, requiring the common variable set to drop `NAME`.
  Evidence: API returned `HTTP 400` with `error: unknown variable 'NAME'` during the first validation run.
- Observation: The Census API response triggers a tibble name-repair warning when converting to a tibble.
  Evidence: `as_tibble.matrix()` warning about non-unique column names appeared during validation runs.

## Decision Log

- Decision: Keep the pull logic in `1_code/1_0_ingest/census_CBP.R` and build `wi_all` by iterating years and binding rows, rather than creating a new script.
  Rationale: The requirement explicitly points to `census_CBP.R` and asks to fill in the next section of that file.
  Date/Author: 2026-02-02 / Codex
- Decision: Use the simplified RUCC split for this CBP spec: RUCC 1–3 = metro, all others = rural.
  Rationale: The user explicitly requested the simplified variant for this file.
  Date/Author: 2026-02-02 / Codex
- Decision: Treat user-made manual edits to `1_code/1_0_ingest/census_CBP.R` as authoritative and document them without overwriting or reinterpreting the changes.
  Rationale: The user reported manual edits and requested documentation rather than re-implementation.
  Date/Author: 2026-02-02 / Codex

## Outcomes & Retrospective

Implementation complete. `wi_all` pulls 2010–2023 CBP county data for Wisconsin, adds a `year` column, and joins RUCC codes to label `rurality` using the simplified RUCC 1–3 metro split. Validation runs completed successfully with the expected API pull messages; only the known tibble name-repair warning remains. The user reported manual edits to `1_code/1_0_ingest/census_CBP.R` after these runs; revalidation is recommended if those edits change the pull logic or inputs.

## Context and Orientation

The script `1_code/1_0_ingest/census_CBP.R` contains two helper functions: `cbp_get()` to fetch CBP data via the Census API and `cbp_list_vars()` to list available variables for a given year. The file now includes a 2023 variable listing (`vars_2023 <- cbp_list_vars(2023)`) and an example Wisconsin pull (`wi_2023 <- cbp_get(year = 2023, ...)`) followed by `wi_2023$year <- 2023`. The file ends with a comment that signals the next section to be filled in for multi-year data assembly. The requirement from `agent-docs/agent_context/2026_02_02_CBP_pull.md` is to use the helper function to guide creation of a single Wisconsin dataset covering 2010–2023. This work is limited to edits inside the repository; do not write outputs outside the repo. The project instructions discourage network calls unless explicitly approved, so any actual API pulls must be performed only after receiving explicit user approval.

Legacy rurality context: Before adopting the CORI Form D JSON rurality field, the repository classified rurality using USDA RUCC codes joined by county FIPS. For this CBP spec, use the simplified split: RUCC 1–3 = “metro” and all other RUCC codes = “rural.” This split must be applied after building `wi_all` by joining to the RUCC Excel file.

## Data Contracts, Inputs, and Dependencies

The data pull depends on the US Census CBP API and requires an internet connection. It uses R packages `httr2`, `jsonlite`, `dplyr`, `purrr`, and `readr`, all already referenced in `1_code/1_0_ingest/census_CBP.R`. The contract for `cbp_get(year, vars, state, county, naics, lfo, empsz)` is that it returns a tibble with the requested variables plus geography columns `state` and `county` (as returned by the API). The combined output `wi_all` must preserve one row per county–industry combination returned by the API for each year. The plan will add a `year` column to each yearly pull so that `wi_all` can be filtered or grouped by year without relying on external metadata.

If rurality is required for CBP outputs or joins, use county FIPS to join USDA RUCC codes from `0_inputs/Ruralurbancontinuumcodes2023.xlsx` and apply the simplified rule for this spec: RUCC 1, 2, 3 ⇒ “metro”; all other RUCC codes ⇒ “rural.” The join must occur after `wi_all` is assembled so the rural/urban flag is present on the combined multi-year dataset.

## Plan of Work

First, keep the existing `vars_2023` and `wi_2023` example as the template, then design a consistent variable strategy across 2010–2023 by using `cbp_list_vars()` to determine a set of variables that exist in all years. A simple and reliable approach is to choose a short list of core variables (`NAME`, `ESTAB`, `EMP`, `PAYANN`, optionally `PAYQTR1`) and verify their availability across the full year range. If a variable is missing for any year, remove it from the common list to avoid failing year pulls. Then, implement the multi-year Wisconsin pull in the “Collect all Wisconsin Data from 2010 to present” section by mapping over `years <- 2010:2023`, calling `cbp_get()` for each year, and binding the results with `bind_rows`. Add a `year` column before binding. Store the final combined data frame as `wi_all` in memory. Do not overwrite or create output files unless explicitly requested; if a saved output is desired, include a commented-out `write_csv()` line with a repository-relative path and a note that it is optional.

Because earlier CBP years may not accept the `NAICS2017` parameter, the plan should keep `naics = NULL` unless the API parameter name is verified for each year. If a NAICS filter is required for the desired output, add a small helper that maps each year to the correct NAICS parameter (for example `NAICS2007` in earlier years and `NAICS2017` later), and apply it only when the corresponding variable exists in that year’s `cbp_list_vars()` output. Document the chosen approach in the script so the next contributor understands the compatibility decision.

After `wi_all` is created, read `0_inputs/Ruralurbancontinuumcodes2023.xlsx`, build a 5-digit county FIPS code compatible with CBP’s `state` + `county` fields, and join RUCC to label each row as `metro` (RUCC 1–3) or `rural` (all other RUCC values). Keep the RUCC code and the derived rurality label in `wi_all` (or as a new object if the original should remain untouched).

## Concrete Steps

All commands should be run from the repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1. Open and edit `1_code/1_0_ingest/census_CBP.R` to insert the multi-year pull section after the comment `# --- Collect all Wisconsin Data from 2010 to present, call the dataframe WI All`.
2. Add a short block that defines the year range, the shared variable list, and a `purrr::map_dfr()` or `dplyr::bind_rows()` loop that builds `wi_all` with a `year` column.
3. If running locally, execute `Rscript 1_code/1_0_ingest/census_CBP.R` only after explicit user approval for network access, and observe that it completes without error.

Network access constraint: Any command requiring network access must be limited to the Census CBP API calls made by `cbp_get()` and `cbp_list_vars()` within `1_code/1_0_ingest/census_CBP.R`. Do not use network access for any other purpose.

Expected short transcript on successful run (example, not exact):

    [1] "Pulling CBP data for 2010"
    [1] "Pulling CBP data for 2011"
    ...
    [1] "Pulling CBP data for 2023"

## Validation and Acceptance

Acceptance is reached when running `1_code/1_0_ingest/census_CBP.R` yields an in-memory object `wi_all` with a `year` column covering 2010–2023, and when all rows show Wisconsin (`state == "55"`). Sanity checks should include: confirming `min(wi_all$year) == 2010` and `max(wi_all$year) == 2023`, verifying that `n_distinct(wi_all$state) == 1` and equals `"55"`, and spot-checking that core variables (for example `ESTAB`, `EMP`, `PAYANN`) exist and are numeric or NA. If the RUCC join is enabled, confirm that `wi_all` includes a RUCC column and a rurality label where RUCC 1–3 map to `metro` and all other RUCC values map to `rural` (with no unexpected NA for Wisconsin counties).

If a NAICS filter is applied, validate that the NAICS column is present and that the filter value appears consistently across years.

## Idempotence and Recovery

The edits are additive and can be rerun safely. Re-running the script should recreate `wi_all` in memory without modifying any files on disk. If a yearly pull fails due to missing variables, update the shared variable list to exclude the missing variable and retry. If the API rejects the NAICS filter for a given year, set `naics = NULL` for that year and document the compatibility adjustment in the script.

## Artifacts and Notes

Key files:

    1_code/1_0_ingest/census_CBP.R
    agent-docs/agent_context/2026_02_02_CBP_pull.md

No new output files are created by this plan unless explicitly requested.

Plan updated on 2026-02-02 to align with the newly added `vars_2023` and `wi_2023` example pull and the updated marker comment in `1_code/1_0_ingest/census_CBP.R`.

Plan updated on 2026-02-02 to add a network access constraint limiting validation to the CBP API only.

Plan updated on 2026-02-02 to adopt the simplified RUCC 1–3 metro split for this CBP spec and require a RUCC join after `wi_all` is built.

Plan updated on 2026-02-02 to record implementation and validation results for the `wi_all` pull and RUCC join.

Plan updated on 2026-02-02 to document that the user made manual edits to `1_code/1_0_ingest/census_CBP.R` after implementation.
