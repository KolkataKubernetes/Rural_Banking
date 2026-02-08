# Build Updated Pitchbook Descriptives Workbook and Figure Spec (2026-02-08)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a contributor can render `1_code/workbooks/2026_02_08_pitchbook.qmd` directly to a shareable HTML with embedded resources and obtain the full Pitchbook figure set requested in the workbook notes and chunk scaffolding: Figure 1, Figure 2, Figure 3, Figure 3b, Figure 4A, Figure 4B, and Figure 4C. The implementation must populate the existing chunks in that workbook by reusing logic from `1_code/1_2_visualize/scratch/pitchbook_explore.qmd` where possible so grouping, per‑million normalization, and interactive behavior remain consistent with the existing exploratory workflow.

This is an updated initial spec plan. It incorporates user clarifications received on 2026-02-08, including no separate image output path and explicit chunk-level output expectations.

## Progress

- [x] (2026-02-08 18:21Z) Read `1_code/workbooks/2026_02_08_pitchbook.qmd` and extracted requested figures, metrics, and interaction requirements.
- [x] (2026-02-08 18:21Z) Reviewed `agent-docs/PLANS.md` to align this document to ExecPlan requirements.
- [x] (2026-02-08 18:21Z) Inspected existing Pitchbook scripts (`1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R`, `1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R`, `1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R`) and exploratory interactive workbook (`1_code/1_2_visualize/scratch/pitchbook_explore.qmd`) to anchor implementation paths.
- [x] (2026-02-08 18:21Z) Drafted this initial spec plan in `agent-docs/execplans/2026_02_08_pitchbook_specplan.md`.
- [x] (2026-02-08 18:32Z) Read the updated chunked workbook scaffold and integrated user clarifications (render-only workflow, chunk-to-output mapping, and reuse of `pitchbook_explore.qmd` helper logic).
- [x] (2026-02-08 18:32Z) Located prior rationale for 2024 cutover in historical execplans and existing helper logic.
- [x] (2026-02-08 18:32Z) Resolved decision requests with user: fixed `year_max = 2024`, fixed Figure 1 outliers to `CA, NY, MA`, and confirmed dynamic top-10 recomputation under year-slider interactions.
- [ ] Implement chunk population in `1_code/workbooks/2026_02_08_pitchbook.qmd` and validate by rendering.

## Surprises & Discoveries

- Observation: The workbook date metadata has now been aligned with today while the title remains intentionally forward-dated for tomorrow’s send.
  Evidence: `1_code/workbooks/2026_02_08_pitchbook.qmd` now has `date: 2026-02-08` and title `"02/09/2026 Update: Updated Pitchbook Figures"`.
- Observation: Historical project logic explains why 2024 became the normalization boundary in comparable Pitchbook views.
  Evidence: `agent-docs/execplans/2026_01_29_figedits_TC.md` documents that `0_inputs/CORI/fips_participation.csv` has no 2025 annual entries and states that year-based per‑million normalizations dropped 2025.
- Observation: `pitchbook_explore.qmd` operationalizes this same logic using shared-year intersection rather than hardcoding a year.
  Evidence: `build_state_per_million()` computes `year_use <- max(intersect(raw_years, pop_years))`; with current inputs this resolves to 2024.
- Observation: The new workbook already contains explicit chunk placeholders that should be treated as the output contract for implementation.
  Evidence: Chunks present are `confg`, `fig1`, `fig2`, `fig3`, `fig3b`, `fig4`, `fig4a`, `figb`, `fig4c` in `1_code/workbooks/2026_02_08_pitchbook.qmd`.

## Decision Log

- Decision: Treat this as a spec-first planning task only; do not modify analytical scripts yet.
  Rationale: User requested a spec plan update, not implementation in this turn.
  Date/Author: 2026-02-08 / Codex
- Decision: Use the same core input objects and helper patterns established in `1_code/1_2_visualize/scratch/pitchbook_explore.qmd` unless explicitly changed.
  Rationale: User requested consistency with that workbook’s interactive/state-group normalization logic.
  Date/Author: 2026-02-08 / Codex
- Decision: No separate static/interactive file export path is part of this spec; deliverable is rendered Quarto HTML with embedded resources.
  Rationale: User explicitly requested render-only sharing workflow for the `.qmd`.
  Date/Author: 2026-02-08 / Codex
- Decision: Record the 2024 rationale before finalizing the year scope.
  Rationale: User requested explicit historical explanation prior to deciding the final year for this workbook.
  Date/Author: 2026-02-08 / Codex
- Decision: Use `year_max = 2024` for this workbook across figures to maintain internal consistency.
  Rationale: User confirmed a single consistent year cap rather than mixed-year logic.
  Date/Author: 2026-02-08 / Codex
- Decision: Keep Figure 1 outlier exclusions fixed to `CA, NY, MA` for now.
  Rationale: User requested fixed exclusions and deferred threshold-rule experimentation to potential later revisions.
  Date/Author: 2026-02-08 / Codex
- Decision: Year sliders in `fig3b` and `fig4c` must dynamically recompute top-10 selection within the selected range.
  Rationale: User explicitly confirmed dynamic recomputation behavior.
  Date/Author: 2026-02-08 / Codex

## Outcomes & Retrospective

Planning revision complete. The spec now aligns to the updated workbook structure and user clarifications, explicitly ties expected results to each existing code chunk, and captures the project’s documented rationale for why 2024 has been used in prior per‑million normalizations.

## Context and Orientation

Target file: `1_code/workbooks/2026_02_08_pitchbook.qmd`.

This workbook now includes chunk placeholders that define the implementation surface. The expected pattern is to populate those chunks by reusing and adapting logic already present in `1_code/1_2_visualize/scratch/pitchbook_explore.qmd`.

Relevant reference files:

- `1_code/workbooks/2026_02_08_pitchbook.qmd`
- `1_code/1_2_visualize/scratch/pitchbook_explore.qmd`
- `agent-docs/execplans/2026_01_29_figedits_TC.md`

Why 2024 was previously chosen:

- Prior execplan documentation states that `0_inputs/CORI/fips_participation.csv` (used to derive population denominators) does not include annual 2025 values, and explicitly required dropping 2025 for year-based per‑million normalization.
- `pitchbook_explore.qmd` implements a last-common-year rule (`max(intersect(raw Pitchbook years, participation years))`) which selects 2024 given current local inputs.
- Therefore, 2024 is a data-availability boundary tied to denominator construction, not an arbitrary cutoff.

## Data Contracts, Inputs, and Dependencies

Primary dependencies (match `pitchbook_explore.qmd` usage):

- R packages: `tidyverse`, `readxl`, `plotly`.
- `2_processed_data/vol_ts_data.rds`
- `2_processed_data/count_ts_data.rds`
- `2_processed_data/BFS_county.rds` (loaded in precedent workbook; retain only if needed by final chunk logic)
- `0_inputs/CORI/fips_participation.csv`
- `0_inputs/state_fips.csv`
- `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx`
- `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx`

Shared constants and group definitions to keep aligned with `pitchbook_explore.qmd` unless explicitly changed:

- `year_min <- 2015`
- `year_max <- 2024` (locked for this workbook by user decision)
- `midwest_excl_wi <- c("27", "19", "17", "26", "18")`
- `big3 <- c("06", "25", "36")`
- `wi_fips <- "55"`
- Series labels: `National`, `National (excl. CA, MA, NY)`, `Midwest (excl. WI)`, `Wisconsin`

Term definitions (aligned to precedent workbook behavior):

- Per 1 million residents: `value / (population / 1,000,000)` where `population = Force / (Participation / 100)`.
- Last common year rule: compute available years in Pitchbook raw tables and participation data, then use the maximum overlap year for single-year state comparisons.
- Summed deal size (Figure 4A): `(sum capital across selected years) / (sum deals across selected years)` by unit.
- Average deal size (Figure 4B): for each state-year, compute `capital / deals`, then average those annual ratios over selected years.

Output contract for this plan:

- Output is the rendered HTML from `1_code/workbooks/2026_02_08_pitchbook.qmd` with embedded resources; no separate figure export files are required.

## Plan of Work

Populate each existing chunk in `1_code/workbooks/2026_02_08_pitchbook.qmd` by reusing or minimally adapting helper code from `1_code/1_2_visualize/scratch/pitchbook_explore.qmd`.

Keep one shared setup/data-prep block in `confg` that loads dependencies, input data, group vectors, helper functions, and any reusable derived tables. Avoid duplicating transformation logic across figure chunks.

Implement static and interactive figure chunks so each section renders directly in the Quarto document. Do not add `ggsave()` or separate widget file writes unless explicitly requested later.

Use consistent grouping and normalization logic across Figures 2, 3b, and 4C by reusing the same helper functions/series labels from the precedent workbook.

## Chunk-to-Output Mapping

The implementation must satisfy these chunk-level outputs in `1_code/workbooks/2026_02_08_pitchbook.qmd`:

1. `confg`: load packages and data; define shared constants/helpers; create reusable prepped objects used by all subsequent chunks.
2. `fig1`: render Figure 1 map of venture capital committed at state level using the chosen year logic and outlier rule.
3. `fig2`: render Figure 2 line chart of average capital committed per 1 million residents (2015–2024 unless year decision changes), using four-series grouping consistent with precedent workbook.
4. `fig3`: render Figure 3 horizontal bar chart of VC deal count per 1 million residents for top 10 + Wisconsin, summed over analysis window.
5. `fig3b`: render interactive Figure 3 variant, reusing the same metric and ranking basis as `fig3`, with a year-range slider (default full window `2015–2024`) that updates the aggregation window and dynamically recomputes top 10 + Wisconsin for the selected years.
6. `fig4`: optional orienting chunk for Figure 4 section-level setup or narrative (if kept as code, keep it lightweight and non-duplicative).
7. `fig4a`: render Figure 4A static vertical bar chart for top 10 + Wisconsin using summed deal-size definition.
8. `figb`: render Figure 4B static vertical bar chart for top 10 + Wisconsin using average deal-size definition.
9. `fig4c`: render interactive Figure 4C with three controls: metric toggle (`Summed`/`Average`), aggregation mode toggle (`States`/`Groups`, where `Groups` equals Figure 2 grouping structure), and a year-range slider (default full window `2015–2024`) that recomputes values for the selected period; in `States` mode, top-10 + Wisconsin selection must be dynamically recomputed for the selected range.

## Concrete Steps

Run from repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1. Edit `1_code/workbooks/2026_02_08_pitchbook.qmd` to populate `confg`, `fig1`, `fig2`, `fig3`, `fig3b`, `fig4`, `fig4a`, `figb`, and `fig4c`.
2. Reuse helper code from `1_code/1_2_visualize/scratch/pitchbook_explore.qmd` directly where feasible to preserve behavior.
3. Render workbook:

    quarto render 1_code/workbooks/2026_02_08_pitchbook.qmd

4. Verify that all figures appear in the rendered HTML and interactive widgets are embedded.

Expected short transcript excerpt:

    processing file: 2026_02_08_pitchbook.qmd
    output file: 2026_02_08_pitchbook.html

## Validation and Acceptance

Acceptance criteria:

1. `quarto render 1_code/workbooks/2026_02_08_pitchbook.qmd` completes without error.
2. Each required chunk (`confg`, `fig1`, `fig2`, `fig3`, `fig3b`, `fig4a`, `figb`, `fig4c`) executes and contributes expected content to the HTML output.
3. Figure 2 uses the same four group labels and state membership logic as `pitchbook_explore.qmd`.
4. Figures 3/4A/4B enforce top-10-plus-WI behavior.
5. Figure 4C exposes both toggles plus a year-range slider and supports all four combinations (`states/summed`, `states/average`, `groups/summed`, `groups/average`) for any valid selected year window.

Sanity checks:

- Validate that any per‑million metric uses non-missing population denominators for the included years/states.
- Spot-check Wisconsin values for Figure 4A vs Figure 4B to confirm formulas differ where expected.
- Confirm Figure 1 exclusion logic matches fixed exclusions `CA, NY, MA`.

## Idempotence and Recovery

This workflow is idempotent at the document-render level. Re-rendering with unchanged inputs should produce the same HTML content.

If a chunk fails, fix that chunk and rerun `quarto render`; no cleanup of separate output artifacts is needed because this plan does not require figure file export paths.

## Artifacts and Notes

Primary files:

- `1_code/workbooks/2026_02_08_pitchbook.qmd`
- `1_code/1_2_visualize/scratch/pitchbook_explore.qmd`
- `agent-docs/execplans/2026_01_29_figedits_TC.md`
- `agent-docs/execplans/2026_02_08_pitchbook_specplan.md`

## Decision Requests

All current decision requests are resolved as of 2026-02-08. New requests should be added here only if implementation uncovers additional ambiguities.

Plan updated on 2026-02-08 to incorporate user clarifications: workbook date/title intent acknowledged, output strategy changed to render-only HTML, data/input/term definitions aligned to `pitchbook_explore.qmd`, chunk-level output mapping added so implementation can populate existing Quarto chunks directly, and all decision requests resolved (`year_max = 2024`, fixed Figure 1 outliers, dynamic slider recomputation behavior).
