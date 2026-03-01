# Add Wisconsin Rank Labels to Pitchbook Figures 3/3b/4A/4B (2026-02-10)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, readers of `1_code/workbooks/2026_02_08_pitchbook.qmd` will be able to see Wisconsin's rank directly on the chart (in Badger red) in four places: Figure 3, Figure 3b, Figure 4A, and Figure 4B. The rank displayed for Wisconsin will be computed against all 50 states (excluding DC), not only the plotted top-10-plus-Wisconsin subset. This removes ambiguity about where Wisconsin stands nationally and makes rank interpretation immediate without reading bar order manually.

This plan builds directly on the motivation and figure structure already present in `1_code/workbooks/2026_02_08_pitchbook.qmd` and the prior implementation spec in `agent-docs/execplans/2026_02_08_pitchbook_specplan.md`.

## Progress

- [x] (2026-02-10 00:00Z) Reviewed `1_code/workbooks/2026_02_08_pitchbook.qmd` to confirm current chunk names and plotting patterns for Figures 3, 3b, 4A, and 4B.
- [x] (2026-02-10 00:00Z) Reviewed prior Pitchbook spec context in `agent-docs/execplans/2026_02_08_pitchbook_specplan.md`.
- [x] (2026-02-10 00:00Z) Drafted this new spec plan in `agent-docs/execplans/2026_02_10_pitchbook_wi_ranklabel_specplan.md`.
- [x] (2026-02-10 17:54Z) Implemented all-state Wisconsin rank computation and Wisconsin-only label layers in `fig3`, `fig3b`, `fig4a`, and `figb`.
- [x] (2026-02-10 17:54Z) Rendered workbook via `quarto render 1_code/workbooks/2026_02_08_pitchbook.qmd` and confirmed successful execution of chunks `fig3`, `fig3b`, `fig4a`, and `figb`.
- [x] (2026-02-10 17:54Z) Updated this ExecPlan living sections with implementation outcomes and evidence.

## Surprises & Discoveries

- Observation: Figure 4B is rendered from chunk `figb` (not `fig4b`) in the workbook.
  Evidence: `1_code/workbooks/2026_02_08_pitchbook.qmd` uses ````{r figb}```` under the “Figure 4B” header.
- Observation: Figure 3b already rebuilds top-10-plus-Wisconsin membership per year frame, so Wisconsin rank can be computed per frame without changing frame semantics.
  Evidence: `fig3b` frame creation filters each year and orders values before frame assignment.
- Observation: Figure 3b rank labels require a second Plotly trace (`scatter` text) so label color can be forced to Badger red independently of the bar-value labels.
  Evidence: Rank labels were added as a dedicated text trace in the initial view and in each animation frame while the existing bar-value labels remained unchanged.

## Decision Log

- Decision: Standardize the Wisconsin rank label text to `WI rank: #<n>` across all four target figures.
  Rationale: A single label pattern is easier to scan and reduces interpretation differences between static and interactive views.
  Date/Author: 2026-02-10 / Codex
- Decision: Use the existing Wisconsin highlight color `#c5050c` (Badger red) for rank label text.
  Rationale: The workbook already uses this color for Wisconsin bars/marks; using the same value keeps visual meaning consistent.
  Date/Author: 2026-02-10 / Codex
- Decision: Define Wisconsin rank as descending order of the same plotted metric across all 50 states (excluding DC), and then display that national rank on the top-10-plus-Wisconsin charts.
  Rationale: User requested explicit national rank context instead of subset rank within displayed bars.
  Date/Author: 2026-02-10 / Codex
- Decision: Store Figure 3b yearly all-state Wisconsin rank in `fig3b_data` as `wi_rank_all_states` and reuse it in both initial trace and frame updates.
  Rationale: Keeping rank on the prepared frame data avoids recomputation inconsistencies between initial and animated states.
  Date/Author: 2026-02-10 / Codex

## Outcomes & Retrospective

Implementation complete. `1_code/workbooks/2026_02_08_pitchbook.qmd` now computes Wisconsin rank against all states (excluding DC) for Figures 3, 3b, 4A, and 4B, and displays `WI rank: #<n>` in Badger red (`#c5050c`) on each target figure. Render validation succeeded on 2026-02-10 with:

    quarto render 1_code/workbooks/2026_02_08_pitchbook.qmd

Observed render evidence included successful execution of chunks `fig3`, `fig3b`, `fig4a`, and `figb`, and generated:

    1_code/workbooks/2026_02_08_pitchbook.html

## Context and Orientation

Target workbook: `1_code/workbooks/2026_02_08_pitchbook.qmd`.

Relevant chunks and metrics:

- `fig3`: horizontal bars for `dealcount_per_million` using top-10-plus-Wisconsin.
- `fig3b`: interactive horizontal bars with yearly slider, also based on `dealcount_per_million`.
- `fig4a`: vertical bars for `dealsize_summed` using top-10-plus-Wisconsin.
- `figb` (Figure 4B): vertical bars for `dealsize_average` using top-10-plus-Wisconsin.

Existing helper contract:

- `top10_plus_wi(df, value_col, label_col = "state_name")` returns the selected states with Wisconsin included.
- Wisconsin bar/mark color is currently `#c5050c`, treated as the Badger red visual identity for Wisconsin in this workbook.

Rank definition for this plan:

- For each figure metric, build a ranking table over all 50 states (exclude DC, consistent with current workbook filtering) in descending order (largest value = rank 1).
- Wisconsin rank is the rank value where `state_name == "Wisconsin"` in that all-states ranking table.
- The charted bars remain top-10-plus-Wisconsin; only the Wisconsin label text references the all-states rank.

## Data Contracts, Inputs, and Dependencies

Dependencies remain unchanged from the workbook baseline:

- R libraries used in this feature: `tidyverse`, `plotly`, and existing workbook dependencies.
- Input data remain unchanged (Pitchbook and participation inputs already loaded in `confg`).

Output contract changes:

- `1_code/workbooks/2026_02_08_pitchbook.qmd` gains Wisconsin rank label rendering in four figure chunks.
- Rendered output `1_code/workbooks/2026_02_08_pitchbook.html` must visually show a Badger-red `WI rank: #<n>` label in Figures 3, 3b, 4A, and 4B.

Invariants:

- No changes to dataset scope, year window, or top-10-plus-Wisconsin selection rules.
- Existing bar heights/lengths remain unchanged; only Wisconsin rank text is added.

## Plan of Work

Edit `1_code/workbooks/2026_02_08_pitchbook.qmd` only. In each target chunk, compute Wisconsin rank from an all-50-state metric table first, then isolate the Wisconsin row into a small `wi_label_*` object for plotting labels. Add a Wisconsin-only text layer in `#c5050c` with the label format `WI rank: #<n>`.

For static ggplot chunks (`fig3`, `fig4a`, `figb`), keep current bar layers unchanged and append `geom_text()` using Wisconsin-only data. For `fig3` (horizontal bars), place the rank label slightly to the right of the Wisconsin bar endpoint. For `fig4a` and `figb` (vertical bars), place the label slightly above the Wisconsin bar.

For interactive `fig3b`, compute Wisconsin rank for each year against all 50 states for that year, and include that rank text in a Wisconsin-only label element in each frame. Keep existing slider behavior and top-10 turnover unchanged.

## Concrete Steps

Run from repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1. Edit `1_code/workbooks/2026_02_08_pitchbook.qmd`.
2. In `fig3`, `fig4a`, and `figb`, add rank computation and Wisconsin-only `geom_text()` labels colored `#c5050c`.
3. In `fig3b`, add per-year Wisconsin rank computation and a Wisconsin-only text label in each frame, colored `#c5050c`.
4. Render workbook:

    quarto render 1_code/workbooks/2026_02_08_pitchbook.qmd

5. Verify target labels in output HTML.

## Validation and Acceptance

Acceptance criteria:

1. `quarto render 1_code/workbooks/2026_02_08_pitchbook.qmd` completes without error.
2. Figure 3 shows a Badger-red text label `WI rank: #<n>` adjacent to Wisconsin's bar.
3. Figure 3b shows a Badger-red text label `WI rank: #<n>` for Wisconsin and updates correctly as the year slider changes.
4. Figure 4A shows a Badger-red text label `WI rank: #<n>` above Wisconsin's bar.
5. Figure 4B (chunk `figb`) shows a Badger-red text label `WI rank: #<n>` above Wisconsin's bar.
6. Each displayed `WI rank: #<n>` value matches Wisconsin's rank among all 50 states for that figure metric (excluding DC), not rank within the plotted subset.
7. All existing titles, subtitles, and metric values remain unchanged aside from added rank labels.

Sanity checks:

- Spot-check that Wisconsin's displayed rank matches an all-50-state rank table for each figure metric (and each year in Figure 3b).
- Confirm label color is `#c5050c` in each target figure.
- Confirm non-Wisconsin bars are unaffected (same count and values as before).

## Idempotence and Recovery

Edits are idempotent at the workbook level: re-running render with unchanged inputs should produce the same labels and figure values. If a label overlaps due to axis range constraints, adjust only label nudges/offsets without changing data or ranking logic, then rerender.

## Artifacts and Notes

Primary files:

- `1_code/workbooks/2026_02_08_pitchbook.qmd`
- `1_code/workbooks/2026_02_08_pitchbook.html`
- `agent-docs/execplans/2026_02_10_pitchbook_wi_ranklabel_specplan.md`
- `agent-docs/execplans/2026_02_08_pitchbook_specplan.md`

Plan created on 2026-02-10 to scope a focused enhancement requested by user: add Wisconsin rank-number labels in Badger red to figures 3, 3b, 4A, and 4B while preserving all existing figure definitions.
