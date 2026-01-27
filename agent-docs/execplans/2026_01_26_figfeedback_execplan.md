# Update figure scripts for 2026-01-25 figure feedback

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document must be maintained in accordance with `agent-docs/PLANS.md` from the repository root.

## Purpose / Big Picture

After this change, the figure scripts under `1_code/1_2_visualize` will align with the 2026-01-25 figure feedback: revised averaging windows, updated Form D totals from the CORI map JSON, dropped figures clearly labeled, and one new figure added. The user-visible outcome is a new set of figure outputs saved to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures` that match the updated definitions.

## Progress

- [x] (2026-01-26 00:30Z) Review figure feedback requirements and identify affected figure scripts.
- [x] (2026-01-26 00:40Z) Implement updated averaging logic in figures 1–3, 11–12 with single-category x-axis labels.
- [x] (2026-01-26 00:45Z) Update figures 8–9 to use CORI map JSON county-level totals for Wisconsin.
- [x] (2026-01-26 00:50Z) Prefix dropped figure scripts with `DROP_` and add new figure script.
- [x] (2026-01-26 01:10Z) Run updated scripts and confirm outputs in `test_figures`.
- [x] (2026-01-26 01:20Z) Record outcomes and update this ExecPlan.

## Surprises & Discoveries

- Observation: `ggplot2` emitted a build-version warning under R 4.5.2 when running the figure scripts.
  Evidence: `Warning message: package ‘ggplot2’ was built under R version 4.5.2`
- Observation: Figure 8 produced a warning that log10 scaling introduced infinite values (zero or missing totals).
  Evidence: `log-10 transformation introduced infinite values.`

## Decision Log

- Decision: Use the existing intermediate `.rds` files in `2_processed_data` to compute new 10- and 11-year averages within the visualization scripts.
  Rationale: The feedback explicitly says figures 1–3 should use current RDS inputs and the repo already stores the required RDS outputs.
  Date/Author: 2026-01-26 / Codex

- Decision: Save all updated figures to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures` to preserve legacy outputs.
  Rationale: Requested by user; avoids overwriting existing figures.
  Date/Author: 2026-01-26 / Codex

- Decision: Use 2015–2025 inclusive when possible; otherwise use 2016–2025; show a single x-axis label such as “2015–2025 average.”
  Rationale: Clarification provided in the figure feedback answers.
  Date/Author: 2026-01-26 / Codex

- Decision: For figures 8–9, use county-level JSON features where `name_co` ends with “WI”; use `total_amount_raised` for Figure 8 and `num_funded_entities` for Figure 9.
  Rationale: Clarification provided in the figure feedback answers.
  Date/Author: 2026-01-26 / Codex

## Outcomes & Retrospective

Updated figure scripts now produce averaged figures per the feedback, dropped figures are prefixed with `DROP_`, and a new Form D deal size average figure was added. Figures 1–3, 8–9, 11–12, and 18 were executed and outputs were written to the `test_figures` directory, with the expected warning about log scaling in Figure 8.

## Context and Orientation

The visualization scripts live in `1_code/1_2_visualize` and each script writes a single figure. The scripts currently rely on intermediate `.rds` data in `2_processed_data`. The requested changes apply to the following scripts:

- `1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R` (Figure 1: VC deal count) uses `2_processed_data/count_ts_data.rds`.
- `1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R` (Figure 2: VC deal volume) uses `2_processed_data/vol_ts_data.rds`.
- `1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R` (Figure 3: VC deal size) uses the same Pitchbook RDS inputs; it must be recomputed from the same data used in Figures 1 and 2.
- `1_code/1_2_visualize/1_2_8_increment_sold_fig8.R` and `1_code/1_2_visualize/1_2_9_deals_cum_fig9.R` must use county-level totals from `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, filtering to `name_co` values that end in “WI”.
- `1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R` and `1_code/1_2_visualize/1_2_12_dealcount_fig12.R` must collapse to 2016–2025 averages and drop metro vs. non-metro delineation.
- Dropped figures (4, 5, 6, 7, 10, 13, 14) must have their script filenames prefixed with `DROP_`.
- A new figure script must be added for Form D deal size across states (10-year average, 2016–2025), grouped like Figures 11–12 but without metro vs. non-metro delineation.

“Average over 10/11 years” means compute the mean of each series across the requested year range (inclusive) before plotting, rather than showing a yearly time series. For figures 1–3, use 2015–2025 inclusive. For figures 11–12 and the new Form D deal size figure, use 2016–2025 inclusive. Each of these figures should use a single x-axis category label (e.g., “2015–2025 average” or “2016–2025 average”).

## Plan of Work

First, update the VC figures (1–3) to aggregate to averages over 2015–2025. In `1_2_1_vc_dealcount_fig1.R` and `1_2_2_vc_dealvol_fig2.R`, filter the RDS to 2015–2025, compute a single average value per series (and the percent-of-national comparisons), and update titles/subtitles/captions to reflect “2015–2025 average.” The x-axis should be a single label such as “2015–2025 average.” In `1_2_3_vc_dealsize_fig3.R`, recompute deal size by dividing the summed capital committed by the summed deal count across 2015–2025, using the same data inputs as Figures 1–2. Then plot the averaged series with the same single-label x-axis.

Second, update figures 8 and 9 to use the JSON totals from `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`. Read the JSON locally, filter to county-level features where `name_co` ends with “WI,” and use `total_amount_raised` for figure 8 and `num_funded_entities` for figure 9. Replace any previous totals derived from RDS inputs. Update captions to cite the CORI map JSON as the source.

If filtering or aggregating by `name_co` is infeasible (for example, inconsistent county naming), use the county-level geospatial attributes present in the JSON to match Wisconsin counties. Document the exact matching fields used (e.g., `name_co`, any county FIPS or GEOID field, and any geometry-derived join) and record the final filter criteria in the script comments so the match can be audited.

Third, update figures 11 and 12 to average across 2016–2025 and drop metro vs. non-metro delineation. This means removing any RUCC pattern or grouping for metro/rural and producing a single bar per region/series (for the averaged period) with a single x-axis label “2016–2025 average.” For Figure 11 only, normalize to “per 1,000,000 labor force participants” instead of per 100,000; update axis labels and caption accordingly. Update subtitles to “2016–2025 average.”

Fourth, rename the dropped figure scripts by adding a `DROP_` prefix to the filenames in `1_code/1_2_visualize`: figures 4, 5, 6, 7, 10, 13, 14. Do not delete these files. Ensure any references in documentation or figure index files are updated to match the new filenames.

Fifth, add a new figure script (next available figure number) to produce “Form D deal size across states, 2016–2025 average,” grouped like Figures 11–12 but without metro vs. non-metro delineation. Use the same Form D intermediate RDS inputs as in figures 11–12 to compute average deal size by summing total capital and deal count across 2016–2025, then dividing. Use a single x-axis label “2016–2025 average.” Save the figure to the test_figures output directory.

Finally, run the updated figure scripts and confirm outputs are written to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures`.

## Concrete Steps

All commands run from the repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1) Update figure scripts per the Plan of Work. Recommended edits:
   - `1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R`
   - `1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R`
   - `1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R`
   - `1_code/1_2_visualize/1_2_8_increment_sold_fig8.R`
   - `1_code/1_2_visualize/1_2_9_deals_cum_fig9.R`
   - `1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R`
   - `1_code/1_2_visualize/1_2_12_dealcount_fig12.R`
   - `1_code/1_2_visualize/1_2_4_capcommitmap_fig4.R` (rename to `DROP_1_2_4_capcommitmap_fig4.R`)
   - `1_code/1_2_visualize/1_2_5_dealsizemap_fig5.R` (rename to `DROP_1_2_5_dealsizemap_fig5.R`)
   - `1_code/1_2_visualize/1_2_6_newfirms_base_fig6.R` (rename to `DROP_1_2_6_newfirms_base_fig6.R`)
   - `1_code/1_2_visualize/1_2_7_newfirms_laborforce_fig7.R` (rename to `DROP_1_2_7_newfirms_laborforce_fig7.R`)
   - `1_code/1_2_visualize/1_2_10_incremental_formD_fig10.R` (rename to `DROP_1_2_10_incremental_formD_fig10.R`)
   - `1_code/1_2_visualize/1_2_13_dealsize_metro_fig13.R` (rename to `DROP_1_2_13_dealsize_metro_fig13.R`)
   - `1_code/1_2_visualize/1_2_14_fig14.R` (rename to `DROP_1_2_14_fig14.R`)
   - New file: `1_code/1_2_visualize/1_2_18_formd_dealsize_avg_fig18.R` (use this next-numbered slot; keep existing figure numbering/names unchanged).

2) Run the updated scripts. Examples:

   Rscript 1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R
   Rscript 1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R
   Rscript 1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R
   Rscript 1_code/1_2_visualize/1_2_8_increment_sold_fig8.R
   Rscript 1_code/1_2_visualize/1_2_9_deals_cum_fig9.R
   Rscript 1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R
   Rscript 1_code/1_2_visualize/1_2_12_dealcount_fig12.R
   Rscript 1_code/1_2_visualize/1_2_18_formd_dealsize_avg_fig18.R

Expected transcript excerpt (example):

   > [1] "Saving 16.5 x 5.5 in image"

## Validation and Acceptance

Acceptance is met when:

- Figures 1–3 show a single averaged bar group per series for 2015–2025, with subtitles reflecting “2015–2025 average” and a single x-axis label (e.g., “2015–2025 average”).
- Figure 3’s values are computed as (sum of capital committed) divided by (sum of deal count) over 2015–2025, using the same data inputs as Figures 1–2.
- Figures 8–9 use county-level totals from `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json` filtered to `name_co` ending in “WI,” and captions cite the CORI map JSON.
- Figures 11–12 show a single averaged bar group per series for 2016–2025 with no metro vs. non-metro patterns, a single x-axis label (e.g., “2016–2025 average”), and Figure 11 is normalized per 1,000,000 labor force participants.
- Dropped figure scripts are renamed with `DROP_` prefix and remain in `1_code/1_2_visualize`.
- New figure output is created in `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures` and reflects Form D deal size across states for the 2016–2025 average.

Sanity checks:

- The output directory contains updated JPEGs with timestamps after the script run.
- The averaged figures have one x-axis category (e.g., “2015–2025 average” or “2016–2025 average”) instead of yearly labels.
- For Figure 11, the axis label and caption explicitly reference “per 1,000,000 labor force participants.”

## Idempotence and Recovery

These steps are safe to rerun: figures are re-generated and overwrite their own outputs in the test_figures folder. Renaming dropped scripts is a one-time change; if needed, rename them back to their original filenames. Keep any legacy output folders untouched.

## Artifacts and Notes

Example filename expectations (exact names to be updated in the scripts):

  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/1_vc_dealcount.jpeg
  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/2_vc_dealvol.jpeg
  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/3_vc_dealsize.jpeg
  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/8_increment_sold.jpeg
  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/9_deals_cum.jpeg
  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/11_incremental_formD_per_lf_avg.jpeg
  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/12_formD_dealcount_avg.jpeg
  /Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures/18_formD_dealsize_avg.jpeg

Execution notes (excerpt):

  Warning message:
  In scale_fill_viridis_c(...): log-10 transformation introduced infinite values.

## Data Contracts, Inputs, and Dependencies

- R and libraries: Use the same R package set already imported in the figure scripts (primarily `tidyverse`, `scales`, and `ggpattern` where already present). No new packages should be added.

- `2_processed_data/count_ts_data.rds`:
  - Used by `1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R`.
  - Input columns must include `year`, `dealcount_national`, `dealcount_wi`, `dealcount_national_nonoutlier`, `dealcount_midwest`, and percent-of-national fields used in labels (`wi_pct`, `nonoutlier_pct`, `midwest_pct`).
  - Output: one averaged bar per series for 2015–2025.

- `2_processed_data/vol_ts_data.rds`:
  - Used by `1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R`.
  - Input columns must include `year`, `vol_national`, `vol_wi`, `vol_national_nonoutlier`, `vol_midwest`, and percent-of-national fields used in labels.
  - Output: one averaged bar per series for 2015–2025.

- Figure 3 recomputation inputs:
  - Use the same RDS data sources as Figures 1–2; compute deal size as total volume divided by total deal count for each series, using 2015–2025 inclusive.
  - Output: one averaged bar per series for 2015–2025.

- `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`:
  - Used by `1_code/1_2_visualize/1_2_8_increment_sold_fig8.R` and `1_code/1_2_visualize/1_2_9_deals_cum_fig9.R`.
  - The JSON must be parsed locally; use county-level features where `name_co` ends with “WI.” Use `total_amount_raised` for figure 8 and `num_funded_entities` for figure 9; totals should match the CORI interactive map source.
  - If `name_co` matching fails, use the JSON’s county-level geospatial attributes (e.g., county FIPS/GEOID or geometry) to select Wisconsin counties. Document the fallback match fields and criteria in the scripts so the audit trail is explicit.

- `2_processed_data/adj_all.rds` and `2_processed_data/cnt_all.rds`:
  - Used by `1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R` and `1_code/1_2_visualize/1_2_12_dealcount_fig12.R`.
  - Inputs must include year, series groupings, and RUCC flags; outputs must collapse to 2016–2025 averages and remove metro/rural pattern distinctions.
  - Figure 11 output must normalize per 1,000,000 labor force participants.

- Output directory:
  - All figure scripts must write JPEGs to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures`.

## Change Notes

- 2026-01-26: Initial ExecPlan created from `agent-docs/agent_context/2026_1_25_figfeedback.md`.
- 2026-01-26: Updated ExecPlan with clarified averaging windows, single-category x-axis labels, and JSON county-level field requirements from `# ANSWERS TO AGENT QUERIES`.
- 2026-01-26: Added guidance to document county-matching fields and allow geospatial attributes as a fallback if `name_co` matching is infeasible.
- 2026-01-26: Marked progress complete and documented run-time warnings and outputs produced during execution.
