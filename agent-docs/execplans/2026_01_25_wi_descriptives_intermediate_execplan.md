# Refactor WI descriptives into intermediate outputs and isolated figures


This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document must be maintained in accordance with `agent-docs/PLANS.md` from the repository root.

## Purpose / Big Picture


After this change, a user can run one R script to generate intermediate `.rds` datasets for all Wisconsin descriptives and then run each visualization script in `1_code/1_2_visualize` independently to reproduce the figures from `1_code/legacy/WI_report_descriptives.R`. They can verify success by seeing the expected `.rds` files in `2_processed_data` and the figure image files saved by each visualization script without errors.

## Progress


- [x] (2026-01-25 00:00Z) Reviewed `agent-docs/agent_context/2026_1_25_intermediate_output.md`, `agent-docs/ExecPlan_TEMPLATE.md`, and `agent-docs/PLANS.md` to scope requirements.
- [x] (2026-01-25 00:00Z) Reviewed `1_code/legacy/WI_report_descriptives.R` and `1_code/1_2_visualize` to enumerate the transformations and plotting dependencies.
- [x] (2026-01-26 00:00Z) Drafted `1_code/1_1_transform/1_0_1_wi_descriptives.R` to generate intermediate `.rds` outputs in `2_processed_data`.
- [x] (2026-01-26 00:00Z) Updated all scripts in `1_code/1_2_visualize` to load intermediate outputs, include the required preamble, and save to the test output directory.
- [x] (2026-01-26 00:00Z) Created the figure-to-filepath markdown index and updated `README.md` for the new script.
- [ ] (2026-01-26 00:00Z) Ran the intermediate script successfully; visualization runs were blocked from writing to the test output folder due to permissions. See Surprises & Discoveries.

## Surprises & Discoveries


- Observation: RUCC and BDS inputs are now available as repo-local files under `0_inputs`.
  Evidence: User confirmation that `0_inputs/Ruralurbancontinuumcodes2023.xlsx` and `0_inputs/bds2023_st_fa.csv` exist.
- Observation: Visualization scripts cannot write to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures` from this execution environment.
  Evidence: `touch` to that directory returned “Operation not permitted”, and `ggsave` emitted “agg could not write to the given file.”

## Decision Log


- Decision: Treat the instruction to update `1_code/1_1_visualize` as a reference to `1_code/1_2_visualize` because the repository only contains `1_code/1_2_visualize`.
  Rationale: There is no `1_code/1_1_visualize` directory in the repo and the task context explicitly calls out `1_code/1_2_visualize` as the visualization location.
  Date/Author: 2026-01-25 / Codex
- Decision: Use repo-local input paths for RUCC and BDS (`0_inputs/Ruralurbancontinuumcodes2023.xlsx` and `0_inputs/bds2023_st_fa.csv`) and treat Form D yearly CSVs as repo-local under `2_processed_data/formd_years`.
  Rationale: The user confirmed these files are now staged in the repository, so we can avoid network-mounted paths.
  Date/Author: 2026-01-26 / Codex
- Decision: Redirect all visualization outputs to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures` to enable side-by-side comparison with legacy figures.
  Rationale: User requested a separate test output folder for comparison without overwriting legacy outputs.
  Date/Author: 2026-01-26 / Codex

## Outcomes & Retrospective


No outcomes yet. This section will be updated as milestones complete.

## Context and Orientation


`1_code/legacy/WI_report_descriptives.R` currently mixes data ingest, transformation, and plotting for 17 Wisconsin-focused figures. The visualization scripts in `1_code/1_2_visualize` assume these objects already exist in memory and lack a standard preamble, making them non-reproducible and not runnable in isolation. The goal is to move all shared transformation work into a single intermediate script at `1_code/1_1_transform/1_0_1_wi_descriptives.R`, write one `.rds` per intermediate data frame into `2_processed_data`, and then update each visualization script to load only the required `.rds` files and generate the same plots as the legacy script. “Intermediate outputs” in this plan mean data frames that correspond to named transformation steps already present in `1_code/legacy/WI_report_descriptives.R`, saved as `.rds` files with filenames matching the object name.

The plan assumes inputs are already staged locally (no network calls). The canonical file locations are repository-relative and should not rely on external mounts for RUCC, BDS, or Form D yearly CSVs.

## Milestones


Milestone 1 establishes the data pipeline. Create the new intermediate script, ensure it follows the `CORI_formd_new.R` preamble/comment structure, and write all required `.rds` outputs to `2_processed_data` without touching visualization code yet. The milestone is complete when the intermediate script runs end-to-end and produces the full set of expected `.rds` files.

Milestone 2 isolates each figure. Update each script in `1_code/1_2_visualize` to include the standard preamble, load only the packages already used in the legacy script, and read the needed `.rds` inputs. Each script should run from a clean R session and produce the same figure output as the legacy script. This milestone ends when all 17 scripts run independently without error.

Milestone 3 documents and validates. Create the figure-to-filepath index markdown in `agent-docs/agent_context` with entries for all figures, update `README.md` for the new intermediate script, and run validation commands. This milestone is complete when the index is present, README changes are in place, and the full run validates.

## Plan of Work


Start by creating `1_code/1_1_transform/1_0_1_wi_descriptives.R` with the same preamble and section comment style as `1_code/1_0_ingest/CORI_formd_new.R`. The script should load only the packages used in `1_code/legacy/WI_report_descriptives.R` and should not make any network calls. It should read inputs from repository-local paths under `0_inputs` and `2_processed_data/formd_years`. Use the same logic and filters as the legacy script to construct intermediate data frames, then write each as a single `.rds` file in `2_processed_data` with a filename matching the object name. Add a guard at the top (for example, `overwrite <- FALSE`) so the script refuses to overwrite existing outputs unless explicitly enabled.

Next, update each script in `1_code/1_2_visualize` to be runnable in isolation. Each script must have the standardized preamble, load only the packages it actually uses (restricted to the legacy package set), define `theme_im()` and `save_fig()` if needed, and read its required `.rds` inputs from `2_processed_data`. Update each script’s output path so it writes figures to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures`. The scripts should avoid data wrangling that belongs in the intermediate script, except for figure-specific formatting or map-object recreation (for example, `tigris::counties` or `maps::map_data`). If a script cannot be made independent without violating the intermediate-output requirements, stop and document the blocking dependency inline in the script comments.

Finally, create a markdown figure index file in `agent-docs/agent_context` with a four-column table header `| Figure ID | Description | Script | Output File |` and an entry for each of the 17 figures. Use the actual script path under `1_code/1_2_visualize` and the image output filepath written by that script. Update `README.md` to document the new intermediate script with purpose, inputs, outputs, and dependencies.

## Concrete Steps


1) Inspect inputs and confirm paths.
   - Working directory: repository root.
   - Commands:
     - `ls 0_inputs/Pitchbook`
     - `ls 0_inputs/Ruralurbancontinuumcodes2023.xlsx`
     - `ls 0_inputs/bds2023_st_fa.csv`
     - `ls 2_processed_data/formd_years`
   - Expected output: the Pitchbook Excel files listed, the RUCC and BDS files found, and the Form D yearly CSVs listed. No other output is required.

2) Create the intermediate script and write `.rds` outputs.
   - Working directory: repository root.
   - Command: `Rscript 1_code/1_1_transform/1_0_1_wi_descriptives.R`
   - Expected output: no console output unless you add `message()` calls; success is the presence of the `.rds` files in `2_processed_data`.

3) Run each visualization script from a clean R session.
   - Working directory: repository root.
   - Commands (run one at a time):
     - `Rscript 1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R`
     - `Rscript 1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R`
     - `Rscript 1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R`
     - `Rscript 1_code/1_2_visualize/1_2_4_capcommitmap_fig4.R`
     - `Rscript 1_code/1_2_visualize/1_2_5_dealsizemap_fig5.R`
     - `Rscript 1_code/1_2_visualize/1_2_6_newfirms_base_fig6.R`
     - `Rscript 1_code/1_2_visualize/1_2_7_newfirms_laborforce_fig7.R`
     - `Rscript 1_code/1_2_visualize/1_2_8_increment_sold_fig8.R`
     - `Rscript 1_code/1_2_visualize/1_2_9_deals_cum_fig9.R`
     - `Rscript 1_code/1_2_visualize/1_2_10_incremental_formD_fig10.R`
     - `Rscript 1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R`
     - `Rscript 1_code/1_2_visualize/1_2_12_dealcount_fig12.R`
     - `Rscript 1_code/1_2_visualize/1_2_13_dealsize_metro_fig13.R`
     - `Rscript 1_code/1_2_visualize/1_2_14_fig14.R`
     - `Rscript 1_code/1_2_visualize/1_2_15_yearlyaverages_fig15.R`
     - `Rscript 1_code/1_2_visualize/1_2_16_yearly_avg_filing_fig16.R`
     - `Rscript 1_code/1_2_visualize/1_2_17_fig17.R`
   - Expected output: no console output unless you add `message()` calls; success is the presence of each figure image under `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures`.

4) Create the figure index and update README.
   - Working directory: repository root.
   - Command: edit `agent-docs/agent_context/wi_figure_filepath_index.md` and `README.md` by hand or via an editor.
   - Expected output: the markdown index file exists with the required header and 17 rows; README includes a new entry for the intermediate script.

## Validation and Acceptance


Run the intermediate script once from a clean R session and confirm that `2_processed_data` contains all expected `.rds` files. Each `.rds` should load as a single data frame whose object name matches the filename. Run each visualization script independently (as in the Concrete Steps) and confirm that each creates its expected figure file with no errors. Spot-check semantic equivalence for a few representative figures by comparing row counts and key aggregates between legacy and refactored outputs, for example:

- For `count_ts_data`, confirm the number of years equals the legacy script’s years and that the `dealcount_national` value for one year matches.
- For `grp_all_lf`, confirm the computed `pct_of_nat` for Wisconsin in a single year matches the legacy script.
- For `formd_complete`, confirm that RUCC group counts and the presence of both `metro/metro-adjacent` and `rural` levels match the legacy script.
- For map figures 8 and 9, confirm the CRS is preserved (EPSG:5070 as in the legacy script) and that county counts match.

Acceptance is met when the intermediate script runs end-to-end, every visualization script runs without error from a clean session using only the intermediate outputs, and all figure images are produced in `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures` with semantics matching the legacy outputs.

## Idempotence and Recovery


The intermediate script should default to non-destructive behavior by refusing to overwrite existing `.rds` outputs unless an explicit `overwrite <- TRUE` flag is set at the top of the script. This ensures repeat runs do not silently overwrite prior outputs. If a run fails midway, delete only the newly written `.rds` files and re-run; do not delete or modify any other files. Visualization scripts are safe to re-run since they only read `.rds` files and write image outputs; if output images already exist and overwriting is undesired, add a guard check in the script to stop when the output file is present.

## Artifacts and Notes


At completion, the key artifacts will be:

- `1_code/1_1_transform/1_0_1_wi_descriptives.R`
- `.rds` outputs in `2_processed_data` (one per intermediate data frame)
- Updated scripts in `1_code/1_2_visualize`
- `agent-docs/agent_context/wi_figure_filepath_index.md`
- Updated `README.md`

Example `.rds` file name and expected type:

  count_ts_data.rds (data frame with one row per year)

## Data Contracts, Inputs, and Dependencies


Dependencies are limited to the packages already used in `1_code/legacy/WI_report_descriptives.R`: `tidyverse`, `scales`, `readxl`, `ggrepel`, `maps`, `plotly`, `ggpattern`, `sf`, plus the namespaced packages used there (`tigris` and `viridis` via `tigris::counties` and `scale_fill_viridis_c`). The intermediate script and each visualization script must only use these packages. Use `suppressPackageStartupMessages()` and load only what each script needs.

Input files and contracts (paths are repository-local):

- `Pitchbook/Pitchbook_dealcount.xlsx` and `Pitchbook/Pitchbook_dealvol.xlsx`: read via `readxl::read_xlsx`, produce state-by-year deal count/volume data used to create `count_ts_data`, `vol_ts_data`, `dealsize_ts_data`, and the 2024 map inputs.
- `CORI/fips_participation.csv`: read via `readr::read_csv`, required to compute labor-force-normalized BDS and Form D metrics (`grp_all_lf`, `formd_complete` with `adjusted_dollars`).
- RUCC Excel file: `0_inputs/Ruralurbancontinuumcodes2023.xlsx`, read via `readxl::read_excel`, required to map county FIPS to RUCC categories for Form D figures 10–17.
- BDS file: `0_inputs/bds2023_st_fa.csv`, read via `readr::read_csv`, required for BDS age-0 firm counts used in figures 6 and 7.
- Form D CSV directory: `2_processed_data/formd_years`, read via `list.files(..., pattern = "\\.csv$")` and `readr::read_csv`, required to create `formd_data_US`, `formd_wi_county`, and `formd_complete`.

Intermediate output contracts (each is written to `2_processed_data/<name>.rds` and must be a single data frame named `<name>` in the script):

- `count_ts_data`: columns `year`, `dealcount_national`, `dealcount_national_nonoutlier`, `dealcount_midwest`, `dealcount_wi`, and share columns `nonoutlier_pct`, `midwest_pct`, `wi_pct` as in the legacy calculation.
- `vol_ts_data`: columns `year`, `dealvol_national`, `dealvol_national_nonoutlier`, `dealvol_midwest`, `dealvol_wi`, and share columns `nonoutlier_pct`, `midwest_pct`, `wi_pct`.
- `dealsize_ts_data`: columns `year`, `dealsize_national`, `dealsize_national_nonoutlier`, `dealsize_midwest`, `dealsize_wi`, and share columns `nonoutlier_pct`, `midwest_pct`, `wi_pct`.
- `vol_2024`: columns `State` and `total` for 2024 deal volume with CA/MA/NY excluded.
- `dealsize_2024`: columns `State` and `total` for 2024 deal size.
- `grp_all`: columns `year`, `group`, `firmcount`, `pct_of_nat` for BDS age-0 firm counts.
- `grp_all_lf`: columns `year`, `group`, `firmcount`, `pct_of_nat` for labor-force-normalized BDS counts.
- `formd_data_US`: columns as selected in the legacy script (`entityname`, `cik`, `biz_id`, `stateorcountry`, `stateorcountrydescription`, `zipcode`, `COUNTY`, `entitytype`, `year`, `over100recipientflag`, `incremental_amount`) filtered exactly as in legacy.
- `formd_wi_county`: columns `county_fips`, `total_increment`, `n_filings` summarizing Form D totals for Wisconsin counties.
- `formd_complete`: columns `year`, `st`, `rucc_grp`, `incremental_dollars`, `dealcount`, `adjusted_dollars` with all (year, state, rucc) combinations completed as in the legacy logic.
- `vol_all`: columns `year`, `rucc_grp`, `group`, `value`, `series`, `pct_of_nat`, `year_idx`, `series_idx`, `x_pos` derived exactly from the legacy script.
- `adj_all`: columns `year`, `rucc_grp`, `group`, `value`, `series`, `pct_of_nat`, `year_idx`, `series_idx`, `x_pos` derived exactly from the legacy script for adjusted dollars.
- `cnt_all`: columns `year`, `rucc_grp`, `group`, `value`, `series`, `pct_of_nat`, `year_idx`, `series_idx`, `x_pos` derived exactly from the legacy script for deal counts.
- `metro_all`: columns `year`, `series`, `value`, `pct_of_nat` derived from metro-only Form D deal size logic.
- `rural_all`: columns `year`, `series`, `value`, `pct_of_nat` derived from rural-only Form D deal size logic.
- `formd_yearly_averages`: columns `grp`, `rucc_type`, `mean_amount` matching the grouped data used in figure 15.
- `formd_yearly_avg_filing`: columns `year`, `rucc_type`, `average_filings` matching the grouped data used in figure 16.
- `formd_yearly_avg_raised_biz`: columns `year`, `rucc_type`, `average_raised` matching the grouped data used in figure 17.

Visualization scripts contracts:

- Each script in `1_code/1_2_visualize` must read only the `.rds` files it requires, generate the figure using the same semantics as the legacy script, and write the image to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures`. If any script cannot write to this location, document the reason in the script’s preamble comments.

## Change Notes


- 2026-01-25 / Codex: Initial draft created based on `agent-docs/agent_context/2026_1_25_intermediate_output.md`, `agent-docs/ExecPlan_TEMPLATE.md`, and `agent-docs/PLANS.md`.
- 2026-01-26 / Codex: Updated input paths to repo-local RUCC/BDS files and Form D yearly CSVs per user guidance; removed external input_root references from execution steps.
- 2026-01-26 / Codex: Updated visualization output paths to the test output directory for side-by-side comparison.
- 2026-01-26 / Codex: Marked implementation steps complete and deferred validation pending execution runs.
- 2026-01-26 / Codex: Logged validation attempt results and write-permission constraint in Progress and Surprises.
