# Add BFS-normalized variants of Figures 1, 2, 8, and 9

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, the repository will include four new visualization scripts that mirror Figures 1, 2, 8, and 9 but normalize by Business Formation Statistics (BFS) business applications instead of labor force. The user will be able to run these scripts and generate BFS-normalized versions of the original figures for Wisconsin comparisons. Success is visible when the new scripts run without error, read BFS-derived inputs, and produce the expected output figures with captions that clearly state the BFS denominator.

## Progress

- [x] (2026-02-03 00:00Z) Read `agent-docs/agent_context/2026_2_2_IM_TC_figfeedback.md` and identified the four new scripts requested.
- [x] (2026-02-03 00:00Z) Confirmed BFS denominator timing and alignment (mirror original windows; sum numerator and denominator separately).
- [x] (2026-02-03 00:00Z) Implemented BFS-normalized versions of Figures 1, 2, 8, and 9 as new scripts in `1_code/1_2_visualize/`.
- [ ] Validate each new script locally (no network) and record the output files and quick sanity checks.

## Surprises & Discoveries

- Observation: Not yet assessed.
  Evidence: Pending script review and input inspection.

## Decision Log

- Decision: Create new scripts rather than modifying the existing Figure 1/2/8/9 scripts.
  Rationale: The requirement explicitly requests four new scripts with `1_2_*b_*.R`/`1_2_*c_*.R` names.
  Date/Author: 2026-02-03 / Codex
- Decision: Mirror the original figures’ time windows and sum numerator and BFS denominator separately before computing ratios.
  Rationale: User confirmed BFS normalization should follow the same summing logic as Figure 1 and mirror original time windows.
  Date/Author: 2026-02-03 / Codex
- Decision: Use continuous color scales for BFS-normalized county maps (Figures 8c/9b) to reflect per-application rates.
  Rationale: Ratios per business applications are continuous and map directly to the original Figure 8 style.
  Date/Author: 2026-02-03 / Codex

## Outcomes & Retrospective

Implementation complete. New BFS-normalized scripts were added for Figures 1, 2, 8, and 9, with outputs directed to the 2026_02_03 folder and filenames prefixed per the new figure IDs. Validation is pending.

## Context and Orientation

The project’s primary figure scripts live in `1_code/1_2_visualize/`. Existing figures 1, 2, 8, and 9 use labor force or population normalization (via `0_inputs/CORI/fips_participation.csv` and/or `2_processed_data/county_population_sum.rds`). The BFS data are staged locally as `0_inputs/bfs_county_apps_annual.xlsx` and a processed dataset `2_processed_data/BFS_county.rds` is already present. The new scripts must mirror the original figures’ logic and layout, but replace the denominator with BFS business applications. The scripts should not overwrite existing outputs and should follow repository pathing and output conventions.

## Data Contracts, Inputs, and Dependencies

- BFS data source: `0_inputs/bfs_county_apps_annual.xlsx` (raw) and `2_processed_data/BFS_county.rds` (processed).
- Existing figure inputs:
  - Figure 1: `2_processed_data/count_ts_data.rds` plus participation data.
  - Figure 2: `2_processed_data/vol_ts_data.rds` plus participation data.
  - Figure 8: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json` plus `2_processed_data/county_population_sum.rds`.
  - Figure 9: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`.
- New figures must read BFS data and compute a denominator that matches the geography/years of each figure.
- No network access is required.

## Plan of Work

First, review existing scripts for figures 1, 2, 8, and 9 to identify their inputs, output directories, and normalization steps. Next, create four new scripts in `1_code/1_2_visualize/`:

1) `1_2_1b_vc_dealcount_fig1.R`
2) `1_2_2b_vc_dealvol_fig2.R`
3) `1_2_8c_increment_sold_percap_fig8b.R`
4) `1_2_9b_deals_cum_fig9.R`

Each new script should largely copy the structure of its predecessor but replace any labor-force or population denominator with a BFS business applications denominator. For state-level figures (1 and 2), compute BFS applications per state (sum of county BFS applications) and use that as the denominator for the same year range as the figure. For county-level Figure 8, compute county BFS applications and normalize county values by BFS totals (or per-application) for the same coverage window. For Figure 9, confirm whether the unit is cumulative counts by geography and define whether BFS normalization is per-application or a ratio of totals; document the choice in the script and captions.

Where BFS data are year-varying, mirror the original figures’ time windows by summing numerator and denominator separately over the same period. Specifically: Figures 1b and 2b should use 2015–2024 totals (matching the originals); Figures 8c and 9b should use “since 2010” totals (matching the originals). Update captions to clearly state “per business application” and the BFS year window used.

All four scripts must write outputs to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_02_03`. Prefix each output filename with the script identifier (`1b_`, `2b_`, `8c_`, `9b_`) before the figure name and keep the `.jpeg` extension.

## Concrete Steps

All commands should be run from the repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1. Inspect `1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R`, `1_2_2_vc_dealvol_fig2.R`, `1_2_8_increment_sold_fig8.R`, and `1_2_9_deals_cum_fig9.R` to identify normalization logic and output paths.
2. Create the four new scripts listed above by copying the originals and replacing the denominator with BFS business applications.
3. Run each new script locally with `Rscript <script>` and verify outputs are created in the expected output directory.

## Validation and Acceptance

Acceptance is reached when all four new scripts execute without error and produce outputs with BFS-normalized values. Sanity checks should include:

- Confirm each script reads BFS data from `2_processed_data/BFS_county.rds` (or documents the use of `0_inputs/bfs_county_apps_annual.xlsx` if used directly).
- Verify the denominator is based on BFS business applications, not labor force or population.
- Confirm denominators are summed over the same windows as the originals (2015–2024 for Figures 1/2; since 2010 for Figures 8/9), and that numerator and denominator are summed separately before computing ratios.
- Confirm output filenames are distinct from the original figures and match the new script naming scheme.
- Spot-check a small subset of values to ensure normalization is per BFS applications and not raw counts.

## Idempotence and Recovery

The new scripts are additive. Re-running them should overwrite only their own output files (if output paths are fixed). If an output directory does not exist, create it. If BFS inputs are missing, stop with a clear message rather than producing partial outputs.

## Artifacts and Notes

Key files:

    agent-docs/agent_context/2026_2_2_IM_TC_figfeedback.md
    1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R
    1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R
    1_code/1_2_visualize/1_2_8_increment_sold_fig8.R
    1_code/1_2_visualize/1_2_9_deals_cum_fig9.R

New scripts to be created:

    1_code/1_2_visualize/1_2_1b_vc_dealcount_fig1.R
    1_code/1_2_visualize/1_2_2b_vc_dealvol_fig2.R
    1_code/1_2_visualize/1_2_8c_increment_sold_percap_fig8b.R
    1_code/1_2_visualize/1_2_9b_deals_cum_fig9.R

Plan updated on 2026-02-03 to record implementation of the four BFS-normalized scripts and the map styling choice for county-level outputs.
