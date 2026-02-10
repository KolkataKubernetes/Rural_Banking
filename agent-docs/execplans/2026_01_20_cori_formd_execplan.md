# Verify CORI Form D pull and align logic

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document must be maintained in accordance with `agent-docs/PLANS.md` from the repository root.

## Purpose / Big Picture

This plan verifies that the new `1_code/1_0_ingest/CORI_formd_new.R` implements the same logic as CORI’s Form D pipeline, using the upstream repos staged under `0_inputs/upstream` as the source of truth. After completing the plan, a novice can run a single R script to pull Form D data, apply the CORI cleaning and joining logic, and produce a validation summary that shows whether the logic matches the upstream reference. Success is visible via a new output CSV and a short QC summary table, plus an aggregate comparison to the map-level county data and the Figure 8/11 benchmarks (per-capita Form D incremental amounts over 2014–2018 vs 2019–2023 for rural vs nonrural).

## Progress

- [x] (2026-01-20 16:38Z) Drafted initial ExecPlan and recorded scope/assumptions.
- [x] (2026-01-20 16:55Z) Staged upstream repos from `0_inputs/links.md` under `0_inputs/upstream`.
- [x] (2026-01-20 16:55Z) Inventory inputs in `0_inputs` and confirm availability of required crosswalks and example data.
- [x] (2026-01-20 18:07Z) Determine feasibility of comparing against `formd-interactive-map` county aggregates; record decision and rationale.
- [x] (2026-01-20 18:07Z) Implement `1_code/1_0_ingest/CORI_formd_new.R` with aligned logic and a QC summary output.
- [x] (2026-01-20 18:07Z) Run validation steps and capture comparison evidence in outputs (attempted run timed out before outputs were written; plan administratively closed).

## Surprises & Discoveries

- Observation: `formd-interactive-map` contains a precomputed `formd_map.json` GeoJSON with county-level aggregates, but no visible ETL code for the aggregation.
  Evidence: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json` is a GeoJSON with fields like `total_amount_raised` and `num_funded_entities`.
- Observation: Running `CORI_formd_new.R` timed out during processing after loading cached Form D data; no outputs were written yet.
  Evidence: `Rscript 1_code/1_0_ingest/CORI_formd_new.R` timed out after 120s, and `1_processed_data` remains empty.

## Decision Log

- Decision: Create a new script `1_code/1_0_ingest/CORI_formd_new.R` for aligned logic and validation outputs.
  Rationale: User requested a clean implementation to compare against the original script without overwriting.
  Date/Author: 2026-01-20 / Codex
- Decision: Treat the upstream repos staged in `0_inputs/upstream` as the source of truth for CORI logic (README method + `dform` data pull), and use `formd_map.json` as an aggregate validation target where feasible.
  Rationale: User requested using CORI GitHub repos as the reference; `formd-interactive-map` documents method and includes aggregates, while `dform` defines raw data ingestion and deduping.
  Date/Author: 2026-01-20 / Codex
- Decision: Treat `formd_map.json` as an all-time aggregate and validate the derived aggregates against Figures 8 and 11 from the CORI report.
  Rationale: User specified the map data is all-time and requested validation against specific figures.
  Date/Author: 2026-01-20 / Codex
- Decision: Use the reported Figure 8 per-capita Form D incremental amounts as validation targets: rural $73 (2014–2018) and $112 (2019–2023), nonrural $729 (2014–2018) and $802 (2019–2023).
  Rationale: User provided exact figure values and time windows from the report for validation.
  Date/Author: 2026-01-20 / Codex

## Outcomes & Retrospective

Planning stage only. No outcomes yet.

## Context and Orientation

The repository contains `1_code/1_0_ingest/CORI_formd.R`, which pulls Form D data using the `dform` R package and applies cleaning and joining logic. The project context is documented in `agent-docs/agent_context/1_Project Overview.md`, including CORI’s intended logic for issuers vs. offerings, ZIP-to-county assignment, and incremental fundraising calculations. Inputs should be assumed to live under `0_inputs` for now, including the HUD ZIP-to-county crosswalk at `0_inputs/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx`. Upstream reference repos are staged at `0_inputs/upstream/formd-interactive-map` (methodology plus `formd_map.json` aggregates) and `0_inputs/upstream/dform` (raw data download/merge/dedupe). The plan will create a new script `1_code/1_0_ingest/CORI_formd_new.R` and produce new outputs without overwriting existing outputs. Validation will rely on the methodology in `0_inputs/upstream/formd-interactive-map/README.md` and the benchmarks in Figures 8 and 11 of `agent-docs/agent_context/CORI_Rural-America-Struggle-Access-Private-Capital_May2025-compressed.pdf`, including the reported per-capita Form D incremental amounts.

“Form D data” refers to SEC offering filings, split into two data frames by CORI: “issuers” (entities filing) and “offerings” (fundraise events). “CORI logic” refers to the documented steps in `agent-docs/agent_context/1_Project Overview.md` and the implementation in the `dform` package and/or the `formd-interactive-map` repo.

## Plan of Work

First, confirm the upstream snapshots exist under `0_inputs/upstream` and inventory required inputs under `0_inputs` (notably the HUD crosswalk). Next, review `0_inputs/upstream/formd-interactive-map/README.md` to extract the published methodology and compare it to the logic in `agent-docs/agent_context/1_Project Overview.md`. Then review `0_inputs/upstream/dform/R/dForm.R` to confirm how raw Form D data is downloaded, cached, and deduplicated. Determine how to align an all-time aggregate from `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json` with the derived outputs (for example, aggregate all available years/quarters in the pull). Next, implement `1_code/1_0_ingest/CORI_formd_new.R` by copying the structure of `CORI_formd.R` but updating pathing to `0_inputs`, parameterizing year/quarter inputs, and mirroring CORI’s logic from the upstream repos and project overview notes. Add a QC summary section that writes a small CSV report (counts, duplicates, negative increments) to a new output path, and ensure outputs do not overwrite existing files. Finally, run the new script for a defined time window (or all-time, if feasible) and capture evidence in the QC summary to validate alignment, then validate against Figure 8 and Figure 11 benchmarks from the CORI report, using the provided per-capita targets for 2014–2018 and 2019–2023 (rural vs nonrural).

In addition, document in the script how to install and use the `dform` package from the staged upstream repo (`0_inputs/upstream/dform`) so the data pull and aggregation logic are reproducible without relying on network access. Note that `formd-interactive-map` itself does not include the aggregation pipeline; it consumes precomputed `formd_map.json` and per-county JSON from external storage. The aggregation procedure must therefore be implemented in `CORI_formd_new.R` using the upstream methodology.

## Concrete Steps

1) Confirm upstream snapshots exist and inventory required inputs under `0_inputs`.
   Working directory: repository root.
   Command: `ls 0_inputs/upstream` and `ls 0_inputs/CORI/HUD_crosswalks`.
   Expected result: `formd-interactive-map`, `dform`, and `ZIP_COUNTY_122020.xlsx` are present.

2) Determine feasibility of comparing against `formd-interactive-map` county aggregates and CORI report figures.
   Working directory: repository root.
   Commands:
     - Inspect `0_inputs/upstream/formd-interactive-map/README.md` for methodology.
     - Inspect `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json` to confirm aggregate fields.
     - Locate Figures 8 and 11 in `agent-docs/agent_context/CORI_Rural-America-Struggle-Access-Private-Capital_May2025-compressed.pdf` and note the exact metrics and groupings used.
   Expected result: A decision logged in `Decision Log` about whether `formd_map.json` can be used as an aggregate validation target for the chosen data scope.

3) Implement `1_code/1_0_ingest/CORI_formd_new.R`.
   Edit location: `1_code/1_0_ingest/CORI_formd_new.R` (new file).
   Content requirements in prose:
   - Include a short setup section showing how to install `dform` from the local upstream snapshot (e.g., `remotes::install_local('0_inputs/upstream/dform')`) and note any required dependencies such as `htmltab`.
   - Use repository-relative paths for inputs, especially the HUD crosswalk in `0_inputs/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx`.
   - Mirror the issuer/offering cleaning logic from the `dform` package and `agent-docs/agent_context/1_Project Overview.md`.
   - Parameterize the year/quarter inputs in a small config section at the top of the script.
   - Produce two outputs: (a) cleaned/joined data as a CSV (e.g., `1_processed_data/formd_2024_new.csv`), and (b) a QC summary CSV (e.g., `1_processed_data/formd_2024_qc_summary.csv`). Create `1_processed_data` if it does not exist.
   - Include a short, explicit comment block describing assumptions and deviations, if any.

4) Validate the new script against the chosen reference.
   Working directory: repository root.
   Command: `Rscript 1_code/1_0_ingest/CORI_formd_new.R`.
   Expected result: output CSVs created and QC summary populated.

## Validation and Acceptance

Acceptance is met when the new script runs without error and produces:
- A cleaned/joined CSV with expected columns and row counts.
- A QC summary CSV with at least these checks: total issuers, total offerings, total joined rows, unique accession counts, count of negative incremental amounts, and count of unmatched ZIPs.
- A comparison summary that shows aggregate totals aligned with `formd_map.json` (treated as all-time) within an agreed tolerance or exact matches where appropriate.
- A comparison summary that shows how the derived aggregates align with Figures 8 and 11 from the CORI report, including explicit notes on any mismatch in definitions, time windows, or denominators. For Figure 8, the targets are: rural $73 per capita (2014–2018) and $112 per capita (2019–2023); nonrural $729 per capita (2014–2018) and $802 per capita (2019–2023).

Sanity checks:
- The count of primary issuers joined to offerings is non-zero for the target year/quarter.
- The sum of `incremental_amount` within a funding round equals the final `totalamountsold` (or is within a small tolerance for rounding).
- Negative `incremental_amount` rows are either zero or explicitly reviewed and explained in the QC summary.

## Idempotence and Recovery

The script is safe to re-run because outputs are written to new filenames and can be overwritten intentionally. If a run fails mid-way, delete only the partial outputs in `1_processed_data` and re-run. If the HUD crosswalk is missing, stop and request the file rather than creating a placeholder.

## Artifacts and Notes

Expected QC summary columns (example):
  - year, quarter, issuers_count, offerings_count, joined_count, unique_accession_count, negative_incremental_count, unmatched_zip_count

Example output location:
  - `1_processed_data/formd_2024_new.csv`
  - `1_processed_data/formd_2024_qc_summary.csv`

## Data Contracts, Inputs, and Dependencies

Dependencies:
- R (base) with packages: `dform`, `httr`, `tidyverse`, `readxl`, `stringr`, `dplyr`.
- If `dform` or its dependencies are not installed, installation may require network access and should be explicitly approved.
  - Prefer installing from the local snapshot at `0_inputs/upstream/dform` to avoid network dependency.

Input contracts:
- `0_inputs/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx` must contain columns `ZIP`, `BUS_RATIO`, `TOT_RATIO`, and `COUNTY` as used in `CORI_formd.R`.
- `0_inputs/CORI/fips_participation.csv` provides labor force participation data with `FIPS`, `year`, and `Force` columns for per-capita (per 100,000 labor force) calculations.
- `0_inputs/upstream/formd-interactive-map/README.md` defines the upstream methodology and serves as the textual source of truth.
- `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json` provides all-time county-level aggregates (e.g., `total_amount_raised`, `num_funded_entities`, `geoid_co`) for comparison if scope aligns.
- The `dform` package must return `data$issuers` and `data$offerings` with columns used in the script: `accessionnumber`, `year`, `quarter`, `zipcode`, `city`, `entityname`, `is_primaryissuer_flag`, `cik`, `yearofinc_value_entered`, `yearofinc_timespan_choice`, `sale_date`, `isequitytype`, `isdebttype`, `ispooledinvestmentfundtype`, `isbusinesscombinationtrans`, and `totalamountsold`.

Output contracts:
- The cleaned/joined CSV must preserve one row per issuer-offering join and include `biz_id`, `funding_round_id`, and `incremental_amount`.
- The QC summary CSV must include the sanity check counts described in Validation.

## Change Notes

2026-01-20: Updated plan to use upstream repo snapshots in `0_inputs/upstream` as the source of truth and added aggregate comparison against `formd_map.json`.
Note: This revision reflects the request to stage and rely on CORI’s GitHub repos as authoritative inputs for the validation plan.
2026-01-20: Updated plan to prioritize validation against the upstream methodology README and to validate against Figures 8 and 11 from the CORI report. Also clarified `formd_map.json` as all-time aggregates.
2026-01-20: Added the specific Figure 8 per-capita validation targets for rural vs nonrural (2014–2018 and 2019–2023).
2026-01-20: Added guidance to install `dform` from the staged upstream snapshot and clarified that aggregation must be implemented in `CORI_formd_new.R` because the map repo ships only precomputed aggregates.
2026-01-20: Updated Progress and Surprises to reflect implementation of `CORI_formd_new.R` and the initial timed-out run attempt.
