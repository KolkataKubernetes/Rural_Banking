# 2026-01-29 County-Level Labor Force Pipeline

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `agent-docs/PLANS.md` and must be maintained in accordance with that file.

## Purpose / Big Picture

After this change, the pipeline will use county-level labor force participation data from `0_inputs/CORI/labor_participation` to build population (or labor-force-based) denominators inside `1_code/1_1_transform/1_0_1_wi_descriptives.R`. The visualization scripts will then read only the prepared outputs they need, instead of recalculating denominators from state-level CSVs. This allows figure updates (per-million normalization and county-level mapping) to be consistent with county-based data and avoids state-level approximations.

## Progress

- [x] (2026-01-29 19:00Z) Confirm `0_inputs/CORI/labor_participation` contains annual county Excel files (2010–2024) and a short description file.
- [x] (2026-01-29 19:10Z) Record decision that only Figure 8 needs county-level population; all other figures keep state-level participation from `fips_participation.csv`.
- [x] (2026-01-29 19:25Z) Inspect `laucnty24.xlsx` to confirm column names and header row.
- [x] (2026-01-29 19:35Z) Implement Figure 8–scoped county labor force ingestion and parsing in `1_code/1_1_transform/1_0_1_wi_descriptives.R`.
- [x] (2026-01-29 19:40Z) Create new intermediate outputs (RDS) for Figure 8 normalization (county labor force + population proxy + per‑million totals).
- [x] (2026-01-29 19:45Z) Update Figure 8 visualization script to consume the new outputs (no direct Excel reads).
- [x] (2026-01-29 19:55Z) Record outcomes, validation checks, and missing-data caveats (notably 2025 absence).

## Surprises & Discoveries

- Observation: The county labor force inputs are annual Excel files named `laucnty10.xlsx` through `laucnty24.xlsx` under `0_inputs/CORI/labor_participation`.
  Evidence: Directory listing shows files for years 2010–2024 and no 2025 file.
- Observation: `laucnty24.xlsx` contains the header row in the first row with fields including “LAUS Code”, “State FIPS Code”, “County FIPS Code”, “County Name/Area Title”, “Year”, “Labor Force”, “Employed”, “Unemployed”, and “Unemployment Rate (%)”.
  Evidence: `readxl::read_excel(..., col_names = FALSE)` shows the header as the first row and data beginning on row 2.

## Decision Log

- Decision: Use state-level participation rates from `0_inputs/CORI/fips_participation.csv` with county labor force data to estimate county population as `labor_force / (participation_rate / 100)`.
  Rationale: The county LAUS Excel files do not provide participation rates, but the figures require per‑million population normalization. Applying the state-level participation rate to county labor force provides a consistent, documented approximation.
  Date/Author: 2026-01-29 (Codex)

- Decision: Keep using `0_inputs/CORI/fips_participation.csv` for population normalization in all figures except Figure 8; Figure 8 will use county labor force from the Excel files combined with state-level participation rates as a proxy for county population.
  Rationale: Only Figure 8 requires county-level denominators; other figures are state or region aggregates and can use state-level participation directly, minimizing new ingestion complexity while preserving county detail where needed.
  Date/Author: 2026-01-29 (Codex)

- Decision: For Figure 8’s cumulative “since 2010” totals, use the sum of annual county populations over 2010–2024 as the denominator.
  Rationale: The numerator is a sum of capital over the full period; using summed annual populations keeps numerator and denominator on the same cumulative scale.
  Date/Author: 2026-01-29 (Codex)

## Outcomes & Retrospective

Completed county labor force ingestion and Figure 8 normalization outputs. Figure 8 uses CORI JSON totals as the numerator and county population summed over 2010–2024 (labor force divided by state participation rate) as the denominator, producing per‑million values. Figure 8b provides a per‑resident variant. The remaining verification is a local run of the transform and figure scripts to confirm output files and labels.

## Context and Orientation

The current transformation script `1_code/1_1_transform/1_0_1_wi_descriptives.R` writes the intermediate RDS datasets consumed by visualization scripts under `1_code/1_2_visualize`. It currently uses `0_inputs/CORI/fips_participation.csv` (state-level) for labor force denominators in some figures. We will replace this with a county-level ingest from `0_inputs/CORI/labor_participation`, which contains BLS LAUS annual county averages (Excel format). The goal is to create reusable, cleaned county labor force tables (and any derived population fields) so visualization scripts only read `2_processed_data/*.rds` outputs.

The Excel files likely follow the standard LAUS county table schema, with columns similar to: LAUS Code, State FIPS Code, County FIPS Code, County Name/Area Title, Labor Force, Employed, Unemployed, and Unemployment Rate (%). The exact header row must be detected within each file because BLS workbooks typically include a title block above the data.

## Plan of Work

First, inspect one Excel file (e.g., `0_inputs/CORI/labor_participation/laucnty24.xlsx`) to confirm the header row and columns. The ingestion function should not hardcode row numbers. Instead, it should read the sheet as raw cells (`col_names = FALSE`) and locate the first row containing the header string “LAUS Code” (or “State FIPS Code”) and use that row as the header. Then read the remainder of the sheet as data.

Second, implement a county labor force ingestion block in `1_code/1_1_transform/1_0_1_wi_descriptives.R` that is scoped to Figure 8 needs:

- Enumerate files `laucnty10.xlsx` through `laucnty24.xlsx` with `list.files()` and parse the year from the filename (e.g., `laucnty24` -> 2024, `laucnty10` -> 2010).
- For each file, read the main sheet, detect the header row, and parse the data into standardized columns. Define clear renames to canonical names: `laus_code`, `state_fips`, `county_fips`, `county_name`, `labor_force`, `employed`, `unemployed`, `unemp_rate` (or the closest matches in the file).
- Build a 5-digit county FIPS code as `paste0(state_fips, county_fips)` padded to width 5. Preserve `state_fips` (2-digit) and `county_fips` (3-digit) as separate columns too.
- Convert numeric columns that arrive as text (commas, whitespace) to numeric values.
- Append a `year` column from the filename so all years can be stacked into a single long table.
- Keep only valid county rows (exclude summary or “statewide” rows if present; define a rule such as `county_fips != "000"` or use `county_name` patterns if the file includes state totals).

Third, compute denominators needed for Figure 8 in the transform script:

- For Figure 8 only, join county labor force data to state-level participation rates from `0_inputs/CORI/fips_participation.csv` on `state_fips` and `year`, then compute `population = labor_force / (participation_rate / 100)` at the county-year level. Document this assumption in the ExecPlan and in Figure 8 captions/notes.
- For all other figures, continue to use `0_inputs/CORI/fips_participation.csv` directly for population normalization, as currently implemented (no change in this ExecPlan).
- For Wisconsin county maps, compute per-million values at the county level using the summed annual population over 2010–2024 as the denominator.

Fourth, write new RDS outputs in `2_processed_data` from `1_0_1_wi_descriptives.R` to support Figure 8:

- `labor_force_county.rds`: long table with `year`, `county_fips`, `state_fips`, `county_name`, `labor_force`, `employed`, `unemployed`, `unemp_rate`, and `population` (computed from state participation rates).
- `county_population_sum.rds`: county-level summed population over 2010–2024 (the denominator for Figure 8 per‑million normalization).

Fifth, update the Figure 8 visualization script to use `formd_wi_county_norm.rds` and remove any direct Excel or participation CSV reads from the visualization layer. Document any updated outputs in the README and in the figure filepath index if necessary.

## Concrete Steps

1) Inspect a representative Excel file to confirm header and column names.

   - Recommended command (repo root):

     Rscript -e "library(readxl); x <- read_excel('0_inputs/CORI/labor_participation/laucnty24.xlsx', col_names = FALSE); print(head(x, 20))"

   Use the output to confirm the header row and final column names.

2) Edit `1_code/1_1_transform/1_0_1_wi_descriptives.R` to add a new ingestion block that reads all county Excel files, standardizes columns, computes county population proxies using `fips_participation.csv`, and writes `labor_force_county.rds` plus `formd_wi_county_norm.rds`.

3) Update `1_code/1_2_visualize/1_2_8_increment_sold_fig8.R` to read CORI Form D JSON for the numerator and join `county_population_sum.rds` for the denominator, then use `per_million` for the fill scale.

4) Update `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` as implementation advances.

## Validation and Acceptance

Validation is performed by rerunning the transformation script and selected figure scripts in the user’s local environment.

- Run (repo root):

  Rscript 1_code/1_1_transform/1_0_1_wi_descriptives.R

- Expected artifacts:
  - New RDS files in `2_processed_data`: `labor_force_county.rds`, `county_population_sum.rds`.
  - Figure 8 output uses CORI JSON totals for the numerator and per‑million normalization based on county population proxy for the denominator.

- Sanity checks:
  - County labor force table includes Wisconsin counties (state FIPS “55”) and has data for 2010–2024 only.
- For one Wisconsin county, `per_million` equals `total_increment` divided by `(sum_population / 1,000,000)` where `sum_population` is the sum of annual county population over 2010–2024.

## Idempotence and Recovery

The ingestion and aggregation steps are deterministic and safe to re-run. If a parsing error occurs for a particular year’s workbook, the script should fail with a clear message that identifies the file and missing header, allowing a targeted fix without impacting other years.

## Artifacts and Notes

- `0_inputs/CORI/labor_participation` contains county-level annual LAUS files for 2010–2024; no 2025 data are present as of 2026-01-29.
- Assumption: For Figure 8 only, county population is approximated using state-level participation rates from `0_inputs/CORI/fips_participation.csv` applied to county labor force (`population = labor_force / (participation_rate / 100)`). This must be stated in Figure 8’s caption/notes.
- The BLS data source link is documented locally in `0_inputs/CORI/labor_participation/excel_description.md`; do not fetch data from the network unless explicitly requested.

Change log: 2026-01-29 — Initial ExecPlan created to replace state-level labor force denominators with county-level LAUS Excel inputs.
Change log: 2026-01-29 — Documented assumption to use state-level participation rates to estimate county population for per‑million normalization.
Change log: 2026-01-29 — Executed plan steps to ingest county LAUS files, compute population proxy, write new RDS outputs, and update Figure 8 script; pending local run/validation.
Change log: 2026-01-29 — Corrected Figure 8 to use CORI JSON totals as the numerator and county population sums as the denominator.

Note: Updated the plan to reflect completed implementation steps (county LAUS ingestion, new RDS outputs, Figure 8 script update) so the document remains self‑contained and accurate.
