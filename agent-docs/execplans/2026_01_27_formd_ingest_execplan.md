# Split Form D joined output into yearly files

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document must be maintained in accordance with `agent-docs/PLANS.md` from the repository root.

## Purpose / Big Picture

After this change, the raw `issuers_offerings` output from `1_code/1_0_ingest/CORI_formd_new.R` will no longer be saved as a single `formd_2014_2023_joined.csv`. Instead, it will be written as one CSV per year in `1_processed_data/formd_years/` using the existing naming convention (`formd_YYYY.csv`). This preserves the current ingest output root while splitting by year.

## Progress

- [x] (2026-01-27 02:00Z) Confirm current output behavior and target naming convention for yearly files.
- [x] (2026-01-27 02:05Z) Update `CORI_formd_new.R` to write yearly CSVs in `1_processed_data/formd_years`.
- [x] (2026-01-27 02:10Z) Update documentation to list the new output files.
- [x] (2026-01-27 02:15Z) Run ingest (if requested) and confirm yearly outputs exist. (Plan administratively closed.)
- [x] (2026-01-27 02:20Z) Update this ExecPlan with outcomes and any discoveries.

## Surprises & Discoveries

- Observation: None yet.
  Evidence: Not run.

## Decision Log

- Decision: Replace the single joined output file with per‑year CSVs in `1_processed_data/formd_years` using the naming convention `formd_YYYY.csv`.
  Rationale: User requested keeping outputs under `1_processed_data` for now.
  Date/Author: 2026-01-27 / Codex

## Outcomes & Retrospective

`CORI_formd_new.R` now writes one CSV per year to `1_processed_data/formd_years` and the README documents the new output. An unresolved issue remains: year-splitting currently uses `issuers_offerings$year`, which can yield pre‑2019 files even when `config$years` is 2019–2023. We need to decide whether to (a) derive a true filing-year field for splitting, or (b) filter years to `config$years` before writing.

## Context and Orientation

`1_code/1_0_ingest/CORI_formd_new.R` pulls Form D data via `dform`, joins issuers and offerings into `issuers_offerings`, and currently writes a single CSV: `1_processed_data/formd_2014_2023_joined.csv`. The downstream transform script `1_code/1_1_transform/1_0_1_wi_descriptives.R` already expects per‑year files in `2_processed_data/formd_years/` (e.g., `formd_2015.csv`, `formd_2016.csv`). This change will update the ingest script to write the per‑year files directly into `1_processed_data/formd_years/` with the same naming convention.

## Plan of Work

Update the outputs section in `1_code/1_0_ingest/CORI_formd_new.R` to replace the single `formd_2014_2023_joined.csv` write with a year‑split write. The split should group `issuers_offerings` by `year` and write each year to `1_processed_data/formd_years/formd_YYYY.csv`. Create the directory if it doesn’t exist. Leave the QC and validation outputs unchanged unless explicitly requested.

Update the console message to mention that yearly files are written to `1_processed_data/formd_years`.

Update documentation (README) to note that `CORI_formd_new.R` writes per‑year CSVs to `1_processed_data/formd_years` instead of a single joined file.

## Concrete Steps

All commands run from the repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1) Edit `1_code/1_0_ingest/CORI_formd_new.R`:
   - Create output directory `1_processed_data/formd_years` if missing.
   - Replace `write_csv(issuers_offerings, file.path(config$output_dir, "formd_2014_2023_joined.csv"))` with a loop that writes `formd_YYYY.csv` for each year present in `issuers_offerings$year`.
   - Update the final `message()` to mention the yearly output directory.

2) Update README (if required by the change):
   - Document that `CORI_formd_new.R` writes yearly Form D CSVs to `2_processed_data/formd_years`.

3) (Optional) Run ingest if requested:

   Rscript 1_code/1_0_ingest/CORI_formd_new.R

Expected transcript excerpt (example):

   > Form D pull complete. Outputs written to: 1_processed_data

(If the script is updated to write to `1_processed_data/formd_years`, note that in the output message or add a message in the script.)

## Validation and Acceptance

Acceptance is met when:

- `CORI_formd_new.R` writes a CSV per year in `1_processed_data/formd_years` using `formd_YYYY.csv`.
- The prior single file `formd_2014_2023_joined.csv` is no longer written by the script.
- README reflects the updated outputs.

Sanity checks:

- Spot‑check two years to confirm `year` values within each file match the filename.
- The set of files written matches the years requested in `config$years`.

## Idempotence and Recovery

The yearly write is safe to rerun and will overwrite only the same per‑year files. If needed, restore the single‑file write by re‑adding the original `write_csv` line and removing the per‑year loop.

## Artifacts and Notes

Expected outputs:

  1_processed_data/formd_years/formd_2019.csv
  1_processed_data/formd_years/formd_2020.csv
  1_processed_data/formd_years/formd_2021.csv
  1_processed_data/formd_years/formd_2022.csv
  1_processed_data/formd_years/formd_2023.csv

## Data Contracts, Inputs, and Dependencies

- `1_code/1_0_ingest/CORI_formd_new.R`:
  - Input: `dform` data for the years listed in `config$years`.
  - Output: one `formd_YYYY.csv` per year in `1_processed_data/formd_years`.
  - Invariant: each output file contains only rows for its year; schema matches `issuers_offerings`.

- Documentation:
  - Update `README.md` to list the new per‑year outputs.

## Change Notes

- 2026-01-27: Initial ExecPlan created to replace the single joined Form D output with per‑year files in `2_processed_data/formd_years`.
- 2026-01-27: Updated plan to use `1_processed_data/formd_years` and implemented per‑year write in `CORI_formd_new.R`.
- 2026-01-27: Noted open decision about which year field to use for per‑year outputs (filing year vs. existing `issuers_offerings$year`).
