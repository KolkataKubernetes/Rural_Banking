# Build National CRA Lending and Bank-Headquarters Trend Comparisons

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a contributor can render one self-contained Quarto notebook and directly compare the current Wisconsin Community Reinvestment Act (CRA) patterns with national patterns. The notebook will reproduce the structure and definitions of current banking Figures 8 and 9 at the national level: annual small-business lending frequency and lending volume per 10,000 residents, separated into the same three loan-size buckets and expressed as growth indexes with 2000 equal to 100.

The notebook will also answer whether the decline in Wisconsin-headquartered banks resembles the national decline. It will plot annual Wisconsin and national bank counts on a common 2000-equals-100 index from 2000 through 2024 and display the corresponding endpoint levels and percentage changes. The comparison is descriptive only; it will not introduce a causal interpretation, estimator, or new sample definition beyond the explicit national geography rule below.

The visible deliverables will be `1_code/workbooks/2026_08_24_cra_national_trends.qmd` and the rendered, resource-embedded HTML file `1_code/workbooks/2026_08_24_cra_national_trends.html`. The HTML will contain four figures and the audit tables needed to verify them: the two national CRA counterparts, the headquarters comparison, and a Wisconsin-versus-national time series of mean branches per institution. No existing figure, processed-data artifact, or report output will be overwritten.

## Progress

- [x] (2026-08-24 15:49Z) Read `agent-docs/PLANS.md` in full and aligned this specification with the repository's ExecPlan requirements.
- [x] (2026-08-24 15:49Z) Located the current Wisconsin CRA implementations in `1_code/1_2_visualize/figs_charlie/bank_fig08_lending_frequency_growth.R` and `1_code/1_2_visualize/figs_charlie/bank_fig09_lending_volume_growth.R`.
- [x] (2026-08-24 15:49Z) Located the Wisconsin-headquartered-bank calculation in `1_code/workbooks/2026_05_17_report_soundbites.qmd` and confirmed its institution definition.
- [x] (2026-08-24 15:49Z) Inventoried staged CRA files for 2000–2023, staged FDIC Summary of Deposits files for 2000–2024, and the local denominator file `0_inputs/CORI/fips_participation.csv`.
- [x] (2026-08-24 15:49Z) Confirmed that all required inputs are already local and that the proposed notebook does not require network access.
- [x] (2026-08-24 15:49Z) Identified malformed extra geography rows in `0_inputs/CORI/fips_participation.csv` that must be excluded from national denominators.
- [x] (2026-08-24 15:49Z) Confirmed that every year from 2000 through 2023 has exactly 51 rows matching the standard two-digit state/DC FIPS vector after those malformed extras are excluded.
- [x] (2026-08-24 15:49Z) Drafted this specification in `agent-docs/execplans/2026_08_24_cra_national_trends_specplan.md`.
- [x] (2026-08-24 17:32Z) Created `1_code/workbooks/2026_08_24_cra_national_trends.qmd` with setup, input validation, reusable national CRA loaders, and national population-proxy construction.
- [x] (2026-08-24 17:32Z) Implemented and verified the national counterparts to current Figures 8 and 9, including exact Wisconsin-loader equivalence tests across all years.
- [x] (2026-08-24 17:32Z) Implemented and verified the indexed Wisconsin-versus-national bank-headquarters comparison and its endpoint summary table for 2000–2024.
- [x] (2026-08-24 17:32Z) Rendered the notebook twice successfully, visually inspected the embedded HTML, and confirmed exactly three charts and four tables with no clipping or horizontal overflow.
- [x] (2026-08-24 17:47Z) Added the requested national lending-frequency endpoint table below Figure 8, rerendered successfully, and verified all three bucket rows and endpoint calculations in the HTML.
- [x] (2026-08-24 17:58Z) Replaced the endpoint tables' reversed decline signs with conventional percent changes, made the per-10,000-to-index correspondence explicit, and added render-time assertions that the table changes reproduce the plotted 2023 indexes.
- [x] (2026-08-24 18:21Z) Added and validated the 2000–2024 Wisconsin-versus-national mean branches-per-institution figure and endpoint table using the existing Figure 2c definition.

## Surprises & Discoveries

- Observation: The repository directory is `1_code/workbooks` (plural), not `1_code/workbook` (singular).
  Evidence: Existing Quarto files, including `1_code/workbooks/2026_05_17_report_soundbites.qmd`, all live under `1_code/workbooks`; no singular directory exists.

- Observation: The current Figures 8 and 9 do not use a direct total-resident population series. They derive a denominator as `Force / (Participation / 100)` from `0_inputs/CORI/fips_participation.csv` and label the resulting measure per 10,000 residents.
  Evidence: `load_wi_population_from_participation()` in `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R` implements this formula, and both current figure scripts join that result before indexing.

- Observation: The national denominator file contains 53 rows in both 2000 and 2023, but only 51 rows have standard two-character state/DC FIPS codes.
  Evidence: The extra codes are `037` and `51000`. The file also contains the standard `37` and `51` rows, so padding or truncating the extras would double-count North Carolina and Virginia rather than repair the data.

- Observation: The staged CRA files use three schemas over the requested time range.
  Evidence: Years 2000–2004 are pipe-delimited `aggr/tract_YEAR.txt` files; 2005–2018 are county-level `cra_old/cra_YEAR.csv` files; and 2019–2023 are fixed-width `YYexp_aggr/craYEAR_Aggr_A11.dat` files.

- Observation: The staged FDIC Summary of Deposits panel is complete for every year from 2000 through 2024.
  Evidence: `0_inputs/data_charlie/FDIC` contains `SOD_CustomDownload_ALL_YEAR_06_30.csv` for all 25 years.

- Observation: The initial render exposed a knitr chunk-option syntax difference.
  Evidence: `fig-width` and `fig-height` are not valid inside an R chunk header; changing them to `fig.width` and `fig.height` allowed all 25 notebook blocks to execute.

- Observation: Wisconsin's headquartered-bank decline is almost identical to the national decline over the shared endpoint window.
  Evidence: The rendered endpoint table reports a decline from 357 to 160 banks in Wisconsin, or 55.2 percent, and from 10,089 to 4,541 nationally, or 55.0 percent.

- Observation: The final HTML passes visual layout checks, although Quarto emits a nonblocking Pandoc deprecation warning while embedding resources.
  Evidence: Two full `quarto render` runs completed and produced the HTML. Browser inspection found three images and four tables; all images rendered at 796 by 398 CSS pixels, and every table's scroll width equaled its 796-pixel container width. The only render warning was `Deprecated: --self-contained. use --embed-resources --standalone`, generated internally despite the notebook already using `embed-resources: true`.

- Observation: The rendered HTML is intentionally ignored by the current repository rules even though it exists locally.
  Evidence: `.gitignore` line 17 matches `1_code/workbooks/*.html`; the final file is present at `1_code/workbooks/2026_08_24_cra_national_trends.html` and is approximately 1.4 MB.

- Observation: The initial implementation included an endpoint table for lending volume but not the parallel table for lending frequency.
  Evidence: User review identified the asymmetry. The revised HTML now reports 2000 and 2023 total loan counts, loans per 10,000 denominator units, and percentage declines for all three size buckets immediately below the national Figure 8 counterpart.

- Observation: Expressing the endpoint comparison as a signed `decline` reversed the intuitive sign relative to the growth index.
  Evidence: The former calculation `(2000 - 2023) / 2000` displayed `-23.4%` for the under-$100K per-10,000 series even though its plotted index was 123.4. The revised tables use conventional change `(2023 - 2000) / 2000`, displaying `+23.4%`, `-17.1%`, and `-12.6%`, which correspond directly to indexes 123.4, 82.9, and 87.4.

- Observation: The first render attempt after adding the branches-per-institution figure failed before notebook execution with a transient Quarto runtime bus error.
  Evidence: Re-running the same unchanged command completed all 33 notebook blocks successfully, showing that the failure did not arise from the R logic or data.

- Observation: Mean branches per institution grew in both geographies, but substantially faster nationally.
  Evidence: The endpoint table reports growth from 5.80 to 8.61 branches per institution in Wisconsin, or 48.5 percent, and from 8.40 to 16.82 nationally, or 100.2 percent.

## Decision Log

- Decision: Create the notebook in `1_code/workbooks`, using the existing plural directory.
  Rationale: This follows repository convention and avoids creating a nearly duplicate singular directory because of a wording mismatch in the request.
  Date/Author: 2026-08-24 / Codex

- Decision: Define the national geography as the 50 states plus the District of Columbia, using the standard 51 two-digit FIPS codes and excluding territories.
  Rationale: This is the clearest reproducible meaning of a national state-based comparison and keeps CRA numerators, the denominator proxy, and FDIC headquarters counts on the same geography. The staged CRA data also contain territories, so an explicit rule is necessary.
  Date/Author: 2026-08-24 / Codex

- Decision: Match current Figures 8 and 9 exactly in metric construction, time window, loan buckets, index base, colors, point shapes, reference line, dimensions, and theme; change only the geography and geography-specific title text.
  Rationale: The user's question is whether the identified Wisconsin patterns mirror national trends, so definition and presentation differences would confound the comparison.
  Date/Author: 2026-08-24 / Codex

- Decision: Use the same `Force / (Participation / 100)` denominator proxy as the current Wisconsin figures rather than adding a new population source.
  Rationale: Exact replication requires a consistent denominator definition. Introducing a different national population series would make national and Wisconsin indexes methodologically inconsistent and would require new data acquisition outside the request.
  Date/Author: 2026-08-24 / Codex

- Decision: Exclude, rather than transform, the malformed `037` and `51000` denominator rows.
  Rationale: Standard `37` and `51` rows already exist. Transforming the malformed codes would create duplicate state-year observations and overstate the national denominator.
  Date/Author: 2026-08-24 / Codex

- Decision: Define a bank headquarters as a unique FDIC certificate number (`CERT`) appearing on a main-office record where `BRNUM == 0`. Define Wisconsin headquarters by `STALP == "WI"` and national headquarters by `STALP` belonging to the 50-state-plus-DC abbreviation set.
  Rationale: This exactly preserves the institution definition in `1_code/workbooks/2026_05_17_report_soundbites.qmd` while expanding only the geography. Counting distinct `CERT` values prevents duplicate rows from inflating institution totals.
  Date/Author: 2026-08-24 / Codex

- Decision: Compare Wisconsin and national headquarters trends using two indexes with 2000 equal to 100 and accompany the figure with raw endpoint counts and percentage declines.
  Rationale: An indexed overlay makes the rate and shape of change comparable despite the large difference in levels. The endpoint table preserves the actual institution counts and provides the direct descriptive answer requested by the audience.
  Date/Author: 2026-08-24 / Codex

- Decision: Keep all transformation logic and outputs inside the new Quarto notebook, while sourcing the existing Charlie helper for shared parsers, FDIC loading, and plot styling where appropriate.
  Rationale: The requested deliverable is a workbook, and this keeps the work additive and reviewable without changing the current production figure scripts or shared helper behavior.
  Date/Author: 2026-08-24 / Codex

- Decision: Deliver only the `.qmd` and embedded HTML in this implementation; do not add standalone JPEGs, CSVs, processed data, README edits, or pipeline wiring.
  Rationale: The user requested a Quarto notebook and did not request production integration. The embedded HTML makes every figure and audit table shareable while minimizing side effects.
  Date/Author: 2026-08-24 / Codex

- Decision: Report conventional signed percent change in the CRA endpoint tables and explicitly distinguish raw-total changes from per-10,000 changes.
  Rationale: Positive growth and negative decline map directly to whether the plotted index is above or below 100. Figure 8 and Figure 9 plot the per-10,000 measures, while the raw-total columns answer a different descriptive question.
  Date/Author: 2026-08-24 / Codex

- Decision: Define the new branches-per-institution comparison as the annual arithmetic mean of branch counts among distinct institutions operating in each geography.
  Rationale: This exactly extends the `mean` series in `bank_fig02c_branch_institution_ratio.R`. Wisconsin uses branches with `STALPBR == "WI"`; the national series uses branches located in the 50 states plus District of Columbia. Institutions are distinct `CERT` values and need not be headquartered in the geography.
  Date/Author: 2026-08-24 / Codex

## Outcomes & Retrospective

Implementation is complete. `1_code/workbooks/2026_08_24_cra_national_trends.qmd` now produces a self-contained HTML at `1_code/workbooks/2026_08_24_cra_national_trends.html` with national counterparts to current Figures 8 and 9, a Wisconsin-versus-national headquarters comparison, a Wisconsin-versus-national mean branches-per-institution comparison, six supporting audit/endpoint tables, and concise descriptive findings.

The notebook's generic Wisconsin CRA loader matches `load_cra_wi_frequency_series()` and `load_cra_wi_volume_series()` exactly for all 24 years. Every national raw CRA value is at least the corresponding Wisconsin value, every national denominator year contains exactly 51 valid state/DC rows, malformed `037` and `51000` rows are excluded, and all six national indexes equal 100 in 2000.

The 2023 national frequency indexes are 123.4 for loans under $100,000, 82.9 for loans from $100,000 to $250,000, and 87.4 for loans from $250,000 to $1 million. The corresponding nominal-volume indexes are 124.9, 81.3, and 92.2. These are definition-matched descriptive benchmarks and remain nominal where the current Wisconsin Figure 9 is nominal.

The headquarters comparison gives the clearest answer to the audience's second question: Wisconsin's count declined 55.2 percent from 2000 to 2024, while the national count declined 55.0 percent. The indexed paths and nearly identical endpoint changes show that Wisconsin broadly mirrors the national consolidation trend on this measure.

No existing Wisconsin script, shared helper, processed artifact, README file, TEMP/TEST script, or canonical figure output was changed. The only implementation correction was the R chunk-option syntax discovered on the first render. The final notebook rendered idempotently and passed visual inspection.

Following user review, both CRA endpoint tables now use conventional percent-change signs. The Figure 8 table reports per-10,000 changes of +23.4 percent, -17.1 percent, and -12.6 percent, exactly matching the plotted 2023 indexes after subtracting 100. Render-time assertions enforce that identity for both CRA figures.

The branches-per-institution addition matches the existing Wisconsin Figure 2c mean series exactly in every year. Wisconsin increased from 5.80 branches per institution in 2000 to 8.61 in 2024, while the national mean increased from 8.40 to 16.82. The new section explicitly states that the metric is based on institutions operating branches in the geography, not institutions headquartered there.

## Context and Orientation

The current Wisconsin CRA figures are generated by two standalone R scripts:

- `1_code/1_2_visualize/figs_charlie/bank_fig08_lending_frequency_growth.R` plots loan counts per 10,000 denominator units for three original-loan-size buckets: under $100,000, $100,000–$250,000, and $250,000–$1 million. Each series is divided by its 2000 value and multiplied by 100.
- `1_code/1_2_visualize/figs_charlie/bank_fig09_lending_volume_growth.R` applies the same steps to loan amounts rather than counts.

Both scripts cover 2000–2023. They call functions in `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R`, join annual Wisconsin denominators from `0_inputs/CORI/fips_participation.csv`, draw a dashed horizontal reference at 100, and use the same blue, rust, and green lines and point shapes. In this plan, a growth index is a series rescaled so its value in the base year is exactly 100. An indexed value of 80 therefore means that the per-10,000 measure is 20 percent below its 2000 value; it does not mean the raw count or amount is 80.

The Wisconsin headquarters calculation appears in `1_code/workbooks/2026_05_17_report_soundbites.qmd`. It reads FDIC Summary of Deposits data for 2000 and 2024, treats `BRNUM == 0` as the main office, filters `STALP == "WI"`, and counts distinct `CERT` values. The proposed notebook extends this to every available year from 2000 through 2024 and to the national geography. Nationally, summing each state's same-state-headquartered institutions is equivalent to counting each eligible domestic institution once by the state of its main office.

The notebook must use `knitr::opts_knit$set(root.dir = project_root)` so all local paths resolve from the repository root during rendering. It should follow the established embedded-HTML pattern used by other files in `1_code/workbooks`, including `format: html: embed-resources: true`.

## Data Contracts, Inputs, and Dependencies

The notebook requires R packages `tidyverse`, `readr`, `stringr`, `purrr`, `scales`, and `knitr`. These are already used directly or through `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R`. No Python, API, browser automation, database, or network dependency is permitted.

The national geography contract is a fixed vector of the 51 standard two-digit FIPS codes for the 50 states and District of Columbia. The implementation must use this same vector for CRA numerator rows and denominator rows. It must also derive the matching 51 postal abbreviations for the FDIC headquarters slice. Puerto Rico and the other territories in the source files are excluded.

The CRA input contracts are:

- `0_inputs/data_charlie/CRA/aggr/tract_YEAR.txt` for 2000–2004. These are pipe-delimited files. Required fields are `state`, `report_level`, `num_100k`, `num_250k`, `num_1mil`, `vol_100k`, `vol_250k`, and `vol_1mil`. Retain `report_level == 200` and eligible two-digit state FIPS codes. Amount columns are reported in thousands and must be multiplied by 1,000, matching the current Wisconsin loaders.
- `0_inputs/data_charlie/CRA/cra_old/cra_YEAR.csv` for 2005–2018. These are county-level CSV files. Required fields are `fips`, `loan_count_100k`, `loan_count_250k`, `loan_count_1M`, `loan_vol_100k`, `loan_vol_250k`, and `loan_vol_1M`. Pad `fips` to five characters, derive state FIPS from the first two characters, retain eligible states, and sum county rows nationally. Amount fields are already in dollars and must not be multiplied by 1,000, matching the current Wisconsin loaders.
- `0_inputs/data_charlie/CRA/YYexp_aggr/craYEAR_Aggr_A11.dat` for 2019–2023. These are fixed-width files parsed with `cra_fixed_widths` and `cra_fixed_names` from `_charlie_helpers.R`. Retain `Report_Level == "200"` and eligible `State_FIPS` codes. Required bucket fields are `Loans_U100k_Num`, `Loans_U100k_Amt`, `Loans_100_250_Num`, `Loans_100_250_Amt`, `Loans_250_1M_Num`, and `Loans_250_1M_Amt`. Amount fields are reported in thousands and must be multiplied by 1,000.

The CRA loader must return one row per year for 2000–2023 with columns `year`, `loans_u100k_num`, `loans_100_250_num`, `loans_250_1m_num`, `loans_u100k_amt`, `loans_100_250_amt`, and `loans_250_1m_amt`. Counts and amounts must be numeric and nonnegative. Missing bucket cells may be treated as zero, matching current helper behavior, but a missing annual input file must stop the render with an error naming the file.

The denominator input is `0_inputs/CORI/fips_participation.csv`. Required fields are `FIPS`, `Participation`, `Force`, and `year`. Preserve `FIPS` as character, retain only codes that exactly match the 51-code national geography vector, parse `Participation` and `Force` as numeric, and compute each state-year proxy as `Force / (Participation / 100)`. Sum those 51 state/DC values within year. The national denominator output must contain exactly one positive value for every year from 2000 through 2023. The implementation must not pad or truncate malformed codes before testing membership in the valid FIPS vector.

The FDIC input contract is `0_inputs/data_charlie/FDIC/SOD_CustomDownload_ALL_YEAR_06_30.csv` for every year 2000–2024. Use `load_fdic_sod(year)` from `_charlie_helpers.R`. Required fields are `CERT`, `BRNUM`, and `STALP`. For each year, filter main-office rows with `as.character(BRNUM) == "0"`, then count distinct nonmissing `CERT` values for Wisconsin and for the 50-state-plus-DC set. The resulting panel must contain columns `year`, `geography`, `hq_banks`, and `hq_banks_idx`, with two rows per year and each geography's 2000 index equal to 100.

The output contract is limited to:

- `1_code/workbooks/2026_08_24_cra_national_trends.qmd`
- `1_code/workbooks/2026_08_24_cra_national_trends.html`

The HTML must embed all resources. The notebook may print derived tibbles, but it must not write ad hoc CSV, RDS, JPEG, or PNG files. No current TEMP/TEST script is affected because this work does not alter shared production outputs.

## Milestones

### Milestone 1: Build and audit the national annual input series

At the end of this milestone, the new notebook will load the local CRA files across all three schemas, aggregate only the 50 states plus District of Columbia, construct the national denominator proxy, and create a complete 2000–2023 CRA panel. It will also build annual Wisconsin and national FDIC headquarters counts for 2000–2024. The notebook will print concise audits showing covered years, state/DC denominator counts, missingness, and endpoint values.

Run `quarto render 1_code/workbooks/2026_08_24_cra_national_trends.qmd`. This milestone is accepted when the data-preparation chunks complete, all 24 CRA years and 25 FDIC years are present, every denominator year has 51 unique eligible state/DC codes, and the notebook stops rather than silently proceeding if any required file, year, or base value is absent.

### Milestone 2: Reproduce current Figures 8 and 9 for the national geography

At the end of this milestone, the HTML will contain two national figures that use the same metrics and visual encodings as the Wisconsin Figures 8 and 9. The only substantive change will be that CRA bucket totals and denominator proxies are aggregated across the national geography.

Re-render the notebook and inspect the two figures. This milestone is accepted when both cover 2000–2023, show all three loan-size buckets, have each line equal to 100 in 2000, include the dashed 100 reference, and use the same colors, shapes, legend order, dimensions, and theme as the current scripts.

### Milestone 3: Compare Wisconsin and national headquarters declines

At the end of this milestone, the HTML will contain a two-line indexed comparison of Wisconsin-headquartered banks and nationally headquartered banks from 2000 through 2024. A table directly below the figure will report each geography's bank counts in 2000 and 2024, the absolute decline, and percentage decline.

Re-render the notebook and compare the Wisconsin endpoints to `1_code/workbooks/2026_05_17_report_soundbites.qmd`. This milestone is accepted when the Wisconsin endpoint counts match that existing workbook exactly, both indexed lines equal 100 in 2000, and the table's arithmetic recomputes from the plotted raw series.

### Milestone 4: Render and visually verify the shareable notebook

At the end of this milestone, `1_code/workbooks/2026_08_24_cra_national_trends.html` will be a self-contained, reviewable artifact with all four figures, short method notes, and concise audit tables. There will be no external asset folder because resources are embedded.

Run the final render, open the HTML, and inspect titles, axes, legends, line continuity, and table readability. Record any deviations or warnings in `Surprises & Discoveries`, update `Progress`, and summarize completion in `Outcomes & Retrospective`.

## Plan of Work

Create `1_code/workbooks/2026_08_24_cra_national_trends.qmd`. Use YAML metadata with an informative title, the implementation date, and resource-embedded HTML output. Begin with a short purpose section that states the two audience questions and defines the notebook as a descriptive national benchmark to current Wisconsin results.

In the setup chunk, establish the repository root, set knitr's root directory, load packages, and source `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R`. Define `safe_divide()`, the eligible 51 state/DC FIPS codes, and the eligible FDIC postal abbreviations. Add assertions that the two geography vectors each contain 51 unique values and include Wisconsin.

Add one national CRA loader in the notebook that returns both counts and amounts. Its year-specific branches must reproduce the three schema rules in the data contracts. Prefer one loop over 2000–2023 with explicit branches for 2000–2004, 2005–2018, and 2019–2023 so count and amount transformations cannot drift apart. Each branch must filter geography before aggregation. The final panel must be sorted by year and checked for exactly one row per expected year.

Add a national denominator builder that reads `fips_participation.csv` without altering `FIPS` before membership filtering. Print an audit table with `year`, `eligible_geographies`, `national_population_proxy`, and the number of excluded malformed rows. Stop if any year lacks 51 eligible geographies or has duplicate eligible FIPS codes. Join the annual national denominator to the CRA panel and compute count-per-10,000 and amount-per-10,000 measures before indexing each bucket to its 2000 value.

Add a national frequency figure chunk that mirrors `bank_fig08_lending_frequency_growth.R`. Preserve the three colors (`#2E75B6`, `#BF4D28`, and `#4CAF50`), point shapes, line and point sizes, legend order, dashed line at 100, `charlie_theme()`, legend position, and 10-by-5 aspect. Adapt the title so it clearly says national; preserve the metric and base-year language.

Add a national volume figure chunk that mirrors `bank_fig09_lending_volume_growth.R` using the national amount indexes. Include an endpoint table for 2000 and 2023 in both nominal totals and per-10,000 measures so a reviewer can distinguish an indexed decline from a raw-dollar decline. Do not add inflation adjustment, because the current Figure 9 is nominal and exact replication is the requested comparison.

Add an FDIC headquarters builder that maps `load_fdic_sod()` over 2000–2024. For every year, form one distinct `CERT` set for main offices in Wisconsin and another for main offices in the 51-state/DC national geography. Bind the two series, index each to its own 2000 value, and build an endpoint table with 2000 count, 2024 count, absolute change, and percent change.

Plot the headquarters comparison with year on the horizontal axis and indexed institution count on the vertical axis. Use two clearly distinguishable lines for `Wisconsin` and `United States`, add a dashed 100 reference line, label the subtitle `Growth Index (2000 = 100)`, and use `charlie_theme()` for consistency. The figure must not compare raw counts on a shared axis, since that would make the Wisconsin line unreadable.

Add a fourth figure that extends the existing mean series in `1_code/1_2_visualize/figs_charlie/bank_fig02c_branch_institution_ratio.R`. For each year from 2000 through 2024, count branch records and distinct `CERT` values among branches located in Wisconsin and among branches located in the 50 states plus District of Columbia. Divide branches by institutions, plot one line for each geography, and print 2000/2024 endpoint levels and changes. Assert that the Wisconsin series equals the existing Figure 2c arithmetic mean in every year.

Conclude the notebook with a compact methods-and-interpretation section. It should state the observed direction and relative magnitude of the changes using values calculated in the notebook, explain that parallel indexed movement supports descriptive similarity while differences in slope or endpoint quantify divergence, and avoid causal language. It must also state that the national CRA and FDIC samples cover the 50 states plus District of Columbia and exclude territories.

Do not modify the current Wisconsin scripts, `_charlie_helpers.R`, `1_code/workbooks/2026_05_17_report_soundbites.qmd`, the README, or any existing output. If implementation reveals that exact replication requires such a modification, record it as a decision request rather than expanding scope automatically.

## Concrete Steps

Run all commands from repository root `/Users/indermajumdar/Research/Rural_Banking`.

1. Create `1_code/workbooks/2026_08_24_cra_national_trends.qmd` according to the setup, data, figure, and narrative structure above.
2. Render the notebook:

    quarto render 1_code/workbooks/2026_08_24_cra_national_trends.qmd

3. Confirm the expected output exists:

    test -f 1_code/workbooks/2026_08_24_cra_national_trends.html

4. Re-run the render once without editing inputs to confirm idempotence:

    quarto render 1_code/workbooks/2026_08_24_cra_national_trends.qmd

The expected short render transcript is:

    processing file: 2026_08_24_cra_national_trends.qmd
    output file: 2026_08_24_cra_national_trends.html

No command in this plan should access the network or write outside the repository.

## Validation and Acceptance

The implementation is accepted only if the exact render command completes without error and produces the embedded HTML.

For the CRA data, verify that the national panel has exactly 24 unique years from 2000 through 2023, one row per year, and nonnegative numeric count and amount values for all three buckets. Verify that the national denominator audit has exactly 51 unique eligible FIPS codes in every year, excludes `037` and `51000`, has no duplicate state-year keys, and produces positive annual denominators. Recompute Wisconsin from the same generic loader by filtering to FIPS `55` and verify that its annual bucket totals equal the outputs of `load_cra_wi_frequency_series()` and `load_cra_wi_volume_series()` for every year. This last check proves that national generalization did not alter the current figure definitions.

For the national Figure 8 counterpart, verify that all three series equal exactly 100 in 2000, no line has an internal missing year, and the rendered colors, shapes, legend order, horizontal reference, axis labels, and time window match `bank_fig08_lending_frequency_growth.R`. Also verify that each annual national raw count is at least as large as the corresponding Wisconsin count.

For the national Figure 9 counterpart, apply the same checks to amount series and compare its visual encoding against `bank_fig09_lending_volume_growth.R`. Confirm that the 2005–2018 amount fields were not multiplied by 1,000 and that the other two CRA eras were multiplied by 1,000. Verify that each annual national raw amount is at least as large as the corresponding Wisconsin amount.

For the headquarters comparison, verify that the panel has exactly 50 rows: two geographies for each year from 2000 through 2024. Each base-year index must equal exactly 100, national raw counts must be at least Wisconsin raw counts in every year, and all counts must be positive integers. The Wisconsin 2000 and 2024 counts must match `wi_hq_by_year` in `1_code/workbooks/2026_05_17_report_soundbites.qmd`. Recompute each endpoint percentage as `(count_2024 - count_2000) / count_2000` and confirm it matches the printed summary table.

For the branches-per-institution comparison, verify that the panel has 50 rows, two geographies per year from 2000 through 2024, positive branch and institution counts, and no missing ratios. Recompute every ratio as `branch rows / distinct CERT values`. For Wisconsin, independently form institution-level branch counts and verify that their arithmetic mean equals the plotted ratio in every year, matching `bank_fig02c_branch_institution_ratio.R`.

Finally, visually inspect the rendered HTML. It must contain three legible figures, no clipped titles or legends, no unexplained warnings, and concise source/method notes. The notebook must make it possible to answer both audience questions from the figures and tables without reading source code.

## Idempotence and Recovery

The notebook is read-only with respect to all source data. Re-rendering with unchanged inputs should deterministically replace only its own HTML output and yield the same derived values. It must never overwrite the current Wisconsin JPEGs or any file in `2_processed_data`.

Every input loader must fail early with a path-specific message when a required file is missing. If a render fails partway through, fix the named input or notebook chunk and rerun the same Quarto command; no cleanup or rollback is necessary. If a new CRA schema discrepancy appears, preserve the current Wisconsin scripts, record the discrepancy in this plan, and change the notebook only after verifying how the corresponding Wisconsin year is handled.

To remove an incomplete implementation before it has been accepted, delete only the newly created `.qmd` and its same-basename `.html`; do not remove the `1_code/workbooks` directory or any shared assets. Because this plan itself is the durable implementation record, update its living sections before and after recovery work.

## Artifacts and Notes

The central equivalence to preserve is:

    annual per-10K value = annual bucket total / annual denominator proxy * 10,000
    annual index = annual per-10K value / 2000 per-10K value * 100

The denominator proxy used by the current figures is:

    state-year denominator proxy = Force / (Participation / 100)
    national annual denominator proxy = sum of state-year proxies over 50 states + DC

The headquarters index is:

    annual headquarters index = distinct headquarters in year / distinct headquarters in 2000 * 100

The relevant source-of-truth files for visual and definitional comparisons are:

- `1_code/1_2_visualize/figs_charlie/bank_fig08_lending_frequency_growth.R`
- `1_code/1_2_visualize/figs_charlie/bank_fig09_lending_volume_growth.R`
- `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R`
- `1_code/workbooks/2026_05_17_report_soundbites.qmd`

Plan created on 2026-08-24 after inspecting the current Wisconsin figure code, the headquarters sound-bite calculation, the complete local input inventory, and the malformed national denominator rows. This note exists to satisfy the living-plan change-log requirement in `agent-docs/PLANS.md`; future revisions must append a dated note explaining what changed and why.

Plan updated on 2026-08-24 after implementation to record completed notebook construction, render and visual-QA evidence, the chunk-option correction, headline descriptive results, and the fact that workbook HTML outputs are ignored by the repository's current `.gitignore` rule.

Plan updated on 2026-08-24 after user review to add and validate the lending-frequency endpoint table parallel to the existing lending-volume table.

Plan updated on 2026-08-24 after accuracy review to replace the confusing signed-decline convention with conventional percent change and add explicit table-to-figure consistency assertions.

Plan updated on 2026-08-24 to record the requested Wisconsin-versus-national mean branches-per-institution figure, its definition, endpoint results, validation against existing Figure 2c, and the transient Quarto runtime failure encountered before the successful render.
