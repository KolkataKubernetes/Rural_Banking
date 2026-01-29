# 2026-01-29 Figure Edits (TC)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `agent-docs/PLANS.md` and must be maintained in accordance with that file.

## Purpose / Big Picture

After this change, Figures 1–3, 8–9, 11–12, 15, and 18 will reflect the January 29, 2026 feedback: labels will show levels instead of percent-of-national annotations, selected figures will be normalized “per million population” using the local participation dataset, Figure 9 will clarify year coverage, and Figure 15 will be rebuilt as a pie chart without RUCC categories. The updates will write figures to a new output directory (`/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2`) without overwriting existing outputs. A user can verify the changes by rerunning the visualization scripts and confirming that labels, normalization, and visual forms match the feedback.

## Progress

- [x] (2026-01-29 18:32Z) Read `agent-docs/agent_context/2026_01_29_figfeedback.md` and inventory target figure scripts.
- [x] (2026-01-29 18:32Z) Review current Figure 1–3, 8–9, 11–12, 15, and 18 scripts for labels, normalization, and output paths.
- [ ] Decide how to implement “per million population” normalization (transform step vs visualization step), including how to handle county-level Figure 8 with state-level participation data.
- [ ] Update output directory path in all affected figure scripts and update `agent-docs/agent_context/wi_figure_filepath_index.md` to the new output location.
- [ ] Implement figure-specific edits and update captions/labels to reflect level values and per-million normalization.
- [ ] Document outcomes, acceptance checks, and any discrepancies or caveats discovered during updates.

## Surprises & Discoveries

- Observation: `0_inputs/CORI/fips_participation.csv` appears to be state-level (2-digit) FIPS data and includes a `year` column with no 2025 entries.
  Evidence: File header and sample rows show `FIPS` values like `01`, `02`, `04` and `year` values like `1976` with no county identifiers.

## Decision Log

- Decision: Pending — choose whether to implement “per million population” normalization in `1_code/1_1_transform/1_0_1_wi_descriptives.R` or solely in the visualization scripts.
  Rationale: Transform-level changes could affect multiple downstream outputs, while visualization-only changes keep the adjustment scoped to the requested figures.
  Date/Author: 2026-01-29 (Codex)

- Decision: Pending — confirm how to apply “per million population” normalization to Figure 8 (county map) using state-level participation data, or whether an alternate denominator should be used.
  Rationale: The provided participation data is state-level; applying a single state population denominator to all counties may not match the intended interpretation.
  Date/Author: 2026-01-29 (Codex)

## Outcomes & Retrospective

No changes implemented yet. This plan defines the scope, open decisions, and concrete steps needed to update the figures.

## Context and Orientation

Figure scripts live in `1_code/1_2_visualize` and write JPEG outputs to a hardcoded directory. The relevant scripts are:

- `1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R`
- `1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R`
- `1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R`
- `1_code/1_2_visualize/1_2_8_increment_sold_fig8.R`
- `1_code/1_2_visualize/1_2_9_deals_cum_fig9.R`
- `1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R`
- `1_code/1_2_visualize/1_2_12_dealcount_fig12.R`
- `1_code/1_2_visualize/1_2_15_yearlyaverages_fig15.R`
- `1_code/1_2_visualize/1_2_18_formd_dealsize_avg_fig18.R`

Figures 1–3 read `2_processed_data/count_ts_data.rds` and `2_processed_data/vol_ts_data.rds`. Figures 8–9, 11–12, 15, and 18 use `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`. Figures 11 and 15 also use `0_inputs/CORI/fips_participation.csv` to compute labor force normalization. The participation dataset includes `FIPS`, `Participation`, `Force`, and `year` columns; it does not include 2025 data.

The requested “per million population” normalization is defined as: for a given state-year, estimate population as `Force / (Participation / 100)` and then compute “per million” by dividing the numerator by `(population / 1,000,000)`. When year-based series are used, 2025 values must be removed because the participation file lacks 2025 data. The plan must also document that the BLS annual data website was checked for 2025 data and none was found; the implementation should note that the BLS site was checked but 2025 data are not available.

## Figure-by-Figure Changes

Figure 1 (VC deal count): Remove percent-of-national labels and display level values only; normalize to “per million population” using the participation-based population estimate; drop 2025 from the series when computing the denominator and update the x-axis label/subtitle to reflect the revised period.

Figure 2 (VC capital committed): Remove percent-of-national labels and display level values only; normalize to “per million population” using the participation-based population estimate; drop 2025 from the series when computing the denominator and update the x-axis label/subtitle to reflect the revised period.

Figure 3 (VC deal size): Remove percent-of-national labels and display level values only; keep deal size as a level value (no per-million normalization requested here).

Figure 8 (Form D capital by Wisconsin county): Normalize to “per million population” using the participation-based population estimate; clarify in labels/caption what denominator is used (pending decision on county vs state denominator).

Figure 9 (Form D filings by Wisconsin county): Add explicit year coverage language in subtitle or caption; use the same “since 2010” verbiage used in other Form D JSON figures, while noting that 2025 coverage is unknown.

Figure 11 (Form D capital per labor force participants): Normalize to “per million population” using the participation-based population estimate; remove percent-of-national labels; update axis label, subtitle, and caption to reflect per-million normalization and to note that BLS 2025 data were checked and not found.

Figure 12 (Form D deal count): Normalize to “per million population” using the participation-based population estimate; remove percent-of-national labels; update axis label, subtitle, and caption accordingly.

Figure 15 (Form D filing amounts): Remove RUCC (metro/rural) splits and replot as a pie chart showing shares across groups (Top 3 states, WI, All other states). Keep normalization consistent with the updated per-million approach if applicable, and update labels/caption to match the new chart type.

Figure 18 (Form D deal size across states): Remove percent-of-national labels and display level values only.

## Plan of Work

First, resolve the per-million normalization strategy. The least disruptive approach is to compute per-million values inside the visualization scripts because it localizes the change to the requested figures. If this approach is chosen, add a shared helper block to each relevant script that reads `0_inputs/CORI/fips_participation.csv`, converts `Force` to numeric, computes population as `Force / (Participation / 100)`, filters out year 2025, and aggregates population across the relevant state groups (National, National excl. CA/MA/NY, Midwest excl. WI, Wisconsin). Then divide each figure’s numerator by `(population / 1,000,000)` to yield per-million values. If transform-level changes are preferred, update `1_code/1_1_transform/1_0_1_wi_descriptives.R` to compute and store per-million series in new RDS outputs and adjust all figure scripts to read those new fields; this will require updating output documentation for new artifacts.

Second, update the output directory in each affected script to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2`. Ensure the directory is created if missing. Update `agent-docs/agent_context/wi_figure_filepath_index.md` so each affected figure points to the new output files.

Third, implement figure-specific label and normalization changes:

- Figures 1–2: remove `pct_of_nat` calculations and `geom_text` annotations; ensure captions no longer mention percent-of-national. Apply per-million normalization with the new denominator and update titles/subtitles to the correct year range (likely 2015–2024 if 2025 is dropped). Update the y-axis label to indicate “per million population.”
- Figure 3: remove `pct_of_nat` calculations and `geom_text` annotations; keep y-axis as a level value; update caption to remove percent-of-national wording.
- Figure 8: compute a per-million value for `total_amount_raised` and use that for `fill`. Update the legend title and caption to specify the denominator. If using a state-level denominator, explicitly say “per million Wisconsin residents (statewide denominator)” to avoid ambiguity.
- Figure 9: update the subtitle or caption to “Since 2010 (CORI Form D interactive map totals; year coverage may not include 2025)” or matching the established verbiage in Figures 11–12/18; do not invent a specific end year.
- Figure 11: replace `value_per_100k` with `value_per_million` using population estimates; remove percent-of-national `geom_text`; update y-axis label, subtitle, and caption to reflect per-million normalization and the missing 2025 participation data (including that BLS was checked for 2025 and none found).
- Figure 12: remove percent-of-national `geom_text`; compute per-million normalization similarly to Figure 11; update labels and caption.
- Figure 15: drop RUCC type from grouping; aggregate to `grp` only, compute the desired normalized measure, and render as a pie chart (e.g., `coord_polar(theta = "y")`), with a legend showing group names and slice values/percentages as needed. Update subtitle and caption to explain the grouping and normalization.
- Figure 18: remove percent-of-national `geom_text`; update caption to remove percent-of-national wording.

Fourth, add documentation notes to the plan and figure captions where appropriate about the BLS 2025 data check and the absence of 2025 participation data.

## Concrete Steps

1) Decide on normalization placement and the Figure 8 denominator interpretation. Update the `Decision Log` with the decision and rationale.

2) Edit output directories.

- Update `output_dir` in each of the nine figure scripts listed in Context and Orientation.
- Update `agent-docs/agent_context/wi_figure_filepath_index.md` with the new output file locations.

3) Implement figure-specific edits.

- For each script, update the computation and labels as described in the Plan of Work.

4) Record the changes in `Progress`, `Decision Log`, and `Outcomes & Retrospective`.

Example edit commands (run from repo root):

    rg -n "output_dir" 1_code/1_2_visualize/1_2_*_fig*.R
    rg -n "pct_of_nat|geom_text" 1_code/1_2_visualize/1_2_*_fig*.R

## Validation and Acceptance

Because this environment cannot execute the plotting scripts, validation will be performed by the user. Acceptance criteria:

- Each updated figure script writes to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2` and no longer targets the `test_figures` directory.
- Figures 1, 2, 3, and 18 no longer show percent-of-national annotations in the plot or captions; they display level values only.
- Figures 1, 2, 8, 11, and 12 use “per million population” normalization and state this in the y-axis label or legend.
- Figure 8’s legend/caption clearly states the denominator (statewide vs county-level) used for per-million normalization.
- Figure 9’s subtitle/caption explicitly notes year coverage as “since 2010” with unknown 2025 coverage.
- Figure 15 is a pie chart with no RUCC categories, and the legend reflects the intended group breakdown.

Suggested run commands for user validation (run from repo root, with the environment set up locally):

    Rscript 1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R
    Rscript 1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R
    Rscript 1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R
    Rscript 1_code/1_2_visualize/1_2_8_increment_sold_fig8.R
    Rscript 1_code/1_2_visualize/1_2_9_deals_cum_fig9.R
    Rscript 1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R
    Rscript 1_code/1_2_visualize/1_2_12_dealcount_fig12.R
    Rscript 1_code/1_2_visualize/1_2_15_yearlyaverages_fig15.R
    Rscript 1_code/1_2_visualize/1_2_18_formd_dealsize_avg_fig18.R

Sanity checks (manual):

- Confirm figures render without percent-of-national labels.
- Confirm per-million units are labeled and values are scaled down relative to raw totals.
- Confirm Figure 15 displays as a pie chart with the correct group labels.

## Idempotence and Recovery

These changes are safe to re-run because they only update scripts and output paths. Re-running the scripts overwrites outputs in the new directory, leaving existing outputs untouched. If an output looks incorrect, revert only the affected script to its prior version and re-run that script.

## Artifacts and Notes

- `0_inputs/CORI/fips_participation.csv` has no 2025 data, so per-million normalization must exclude 2025 from denominators, and the captions should note that 2025 participation data were not available (BLS site checked, no annual 2025 data found).
- Output directory to use for all updated figures: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2`.

Change log: 2026-01-29 — Initial ExecPlan created from `agent-docs/agent_context/2026_01_29_figfeedback.md` and existing figure scripts; pending decisions noted for per-million normalization strategy and Figure 8 denominator.
