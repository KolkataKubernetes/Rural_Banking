# Build the Urban/Rural and National Banking Lookbook

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a contributor can render `1_code/workbooks/2026_09_01_urbanrural_national_lookbook.qmd` into a self-contained HTML lookbook. The lookbook will extend the report-facing Wisconsin banking figures in two directions: it will show Wisconsin urban/rural heterogeneity using a 2023-primary USDA Rural-Urban Continuum Code (RUCC) classification with historical-FIPS fallback from the staged 2013 and 2003 vintages, and it will provide directly comparable national figures for the United States.

The lookbook will be descriptive. It will not introduce causal claims, new estimators, inflation adjustment, or loan-size definitions beyond those already used in the report. The new notebook and its same-basename HTML are the only planned deliverables. Existing figure scripts, existing workbooks, processed data, report files, and README files will not be changed.

Implementation began only after the open decisions in `Decision Log` were resolved and the user approved this plan.

## Progress

- [x] (2026-09-01 21:55Z) Read `AGENTS.md`, `agent-docs/PLANS.md`, and the task brief in `agent-docs/agent_context/2026_09_01_urbanrural_national_lookbook.md`.
- [x] (2026-09-01 21:55Z) Initially inspected the report-facing R implementations and rendered the now-superseded `agent-docs/agent_context/docs/2026_08_03_final_report.docx`; its interpretations were subsequently rechecked against the current report below.
- [x] (2026-09-01 21:55Z) Inspected `0_inputs/Ruralurbancontinuumcodes2023.xlsx` and confirmed the established project split: RUCC 1–3 are metropolitan and RUCC 4–9 are nonmetropolitan.
- [x] (2026-09-01 21:55Z) Inventoried the local FDIC, CRA, NCUA, RUCC, and population inputs and tested the relevant join keys.
- [x] (2026-09-01 21:55Z) Identified the missing 2000–2009 nationwide county population denominator and historical county-boundary mismatches as decision gates for the requested four-line CRA panels.
- [x] (2026-09-01 21:55Z) Drafted this specification at `agent-docs/execplans/2026_09_01_urbanrural_national_lookbook_specplan.md`.
- [x] (2026-09-01 22:21Z) Replaced the superseded report reference with `agent-docs/agent_context/docs/2026_small_biz_finance_report.docx` and visually verified the current report-facing Figures 1, 2, 7, 8, 9, and CU-5.
- [x] (2026-09-01 22:21Z) Audited the newly staged 2003 and 2013 RUCC vintages against every 2000–2023 CRA county-year and established a complete historical-FIPS fallback strategy.
- [x] (2026-09-01 22:21Z) Revised the population issue to distinguish parent-geography normalization, which needs no new data, from subgroup-population normalization, which does.
- [x] (2026-09-02 03:14Z) Resolved the CRA denominator as subgroup-specific resident population: each urban/rural numerator will be divided by the population living in the same RUCC subgroup.
- [x] (2026-09-02 03:48Z) User approved the revised specification and authorized implementation.
- [x] (2026-09-01 22:55Z) Staged and hashed the three official Census PEP/intercensal county-population files under `0_inputs/data_charlie/Census/PEP_county_population/`, with source URLs and field contracts in `PROVENANCE.md`.
- [x] (2026-09-01 23:04Z) Created `1_code/workbooks/2026_09_01_urbanrural_national_lookbook.qmd` with the ten approved outputs and embedded calculation audits.
- [x] (2026-09-01 23:07Z) Rendered the resource-embedded HTML twice without input changes, extracted and visually inspected all eight embedded plot images, corrected CU value-label abbreviations, and confirmed the final render.
- [x] (2026-09-01 23:08Z) Updated this living plan with implementation evidence and outcomes.

## Surprises & Discoveries

- Observation: The current finalized report resolves which visible figures the task brief references.
  Evidence: Page 7 of `agent-docs/agent_context/docs/2026_small_biz_finance_report.docx` displays “Figure 2: Wisconsin Banking Institutions by Number of Branches (2024),” and page 19 displays “Figure CU-5: Average Commercial Loan Size.” Those visible figures match the task brief's requested content. Methodology numbering elsewhere in the report does not change the source visuals for this lookbook.

- Observation: The visible report Figure 1 uses all Wisconsin FDIC branch records, despite methodology prose describing a commercial-bank-only subset.
  Evidence: The report endpoints are 365 institutions and 2,116 branches in 2000 and 193 institutions and 1,661 branches in 2024. Those values match all `STALPBR == "WI"` records, whereas the `BKCLASS %in% c("NM", "N", "SM")` subset yields 325/1,720 in 2000 and 169/1,523 in 2024.

- Observation: The requested RUCC split is technically metropolitan/nonmetropolitan rather than a direct urban/rural population classification.
  Evidence: `0_inputs/Ruralurbancontinuumcodes2023.xlsx` defines codes 1–3 as metro and 4–9 as nonmetro. Existing project code in `1_code/1_0_ingest/census_BFS.R`, `1_code/1_0_ingest/census_CBP.R`, and `1_code/workbooks/2026_03_01_windicator_wi_bizgrowth.qmd` uses the same split but labels codes 4–9 `rural`. The notebook should say “Urban/metro (RUCC 1–3)” and “Rural/nonmetro (RUCC 4–9)” at first use, then use the shorter labels in legends.

- Observation: The 2003 and 2013 RUCC vintages solve the historical county-code mismatch without a new external concordance.
  Evidence: A 2023-only join leaves 8–17 distinct CRA county codes unmatched per year. Using 2023 RUCC as the primary classification, then 2013 and 2003 as fallbacks for FIPS codes absent from newer vintages, matches every CRA county-year except `51780` in 2000–2002. Census county-change documentation identifies `51780` as the former South Boston independent city and `51083` (Halifax County) as its successor geography; assigning `51780` the Halifax County RUCC class completes coverage.

- Observation: Applying whole RUCC vintages by decade would change the composition of the urban/rural groups at the vintage boundaries.
  Evidence: Among common FIPS codes, 149 counties switch between the urban/metro and rural/nonmetro groups from the 2003 to 2013 files, and 127 switch from 2013 to 2023. Using older vintages only as missing-FIPS fallbacks preserves the project's established fixed-2023 classification for counties that exist in the current file and avoids classification-driven breaks in 2010 and 2020.

- Observation: The existing national Figure 8 could return to 2000 because it needs only one denominator for the whole nation; the requested four-line figure may need four denominators, depending on the intended interpretation.
  Evidence: `1_code/workbooks/2026_08_24_cra_national_trends.qmd` sums state-level `Force / (Participation / 100)` values into one national annual population proxy. The same local file can also supply one Wisconsin total. It cannot divide either total between urban and rural counties. No new data are needed if rural and urban numerators are divided by their parent Wisconsin or U.S. total population; annual county population data are needed only if each line is intended to mean loans per 10,000 residents living in that specific urban/rural subgroup.

- Observation: Annual Census Population Estimates Program (PEP) and intercensal county totals are a better denominator source than ACS for this 2000–2023 index.
  Evidence: The first ACS product covering every county was the 2005–2009 five-year estimate, and adjacent ACS five-year releases are overlapping period estimates rather than separate annual population snapshots. Census publishes annual county resident-population series for 2000–2010, 2010–2020, and 2020 onward. Splicing the latest official series for each decade provides one July 1 county estimate per analysis year and preserves the requested 2000 base year.

- Observation: Wisconsin FDIC branches have a clean county-FIPS join to RUCC, and Wisconsin NCUA headquarters need only deterministic county-name normalization.
  Evidence: All 1,661 Wisconsin branch records in the 2024 SOD file match RUCC through `STCNTYBR`. For NCUA, the only unmatched Wisconsin headquarters county name in 2017–2024 is capitalization of `Fond Du Lac`; uppercasing and trimming both sources resolves it.

- Observation: `1_code/workbooks/2026_08_24_cra_national_trends.qmd` already contains validated generic CRA loaders for 2000–2023 and a 50-states-plus-DC geography vector.
  Evidence: That workbook verifies its generic Wisconsin series against the current Figure 8 and 9 helper loaders and handles all three staged CRA file schemas. The new lookbook should adapt that tested logic rather than invent another set of unit conversions.

- Observation: All three nationwide population series join completely to the approved RUCC precedence lookup without an additional concordance.
  Evidence: The rendered population audit classifies every eligible county/county-equivalent row in 2000–2023. Classified population equals input county population exactly in every year; the audit displays zero differences at the series endpoints and decade seams.

- Observation: The RUCC workbooks include a small number of territorial “Not Applicable” rows with missing RUCC codes.
  Evidence: The missing codes are for American Samoa and Northern Mariana Islands geographies outside the approved 50-states-plus-DC scope. Filtering the RUCC vintages to the approved state/DC FIPS before assertions preserves strict no-missing classification for the analysis geography.

- Observation: Compact-dollar labels created with `scales::dollar(..., accuracy = 1000, scale_cut = cut_short_scale())` were visually misleading on the CU plots.
  Evidence: The first visual extraction displayed `$0K` and `$1,000K` labels. A deterministic `short_dollar()` formatter now displays values such as `$257K` and `$0.59M`/`$592K` appropriately; the corrected plots were re-rendered and re-inspected.

## Decision Log

- Decision: Use the displayed report figures, rather than inconsistent methodology numbering, as the visual reference.
  Rationale: The user asked for figures inspired by the current report/lookbook and explicitly named the average commercial loan-size content. The current `2026_small_biz_finance_report.docx` confirms that the displayed Figure 2 is the 2024 institution-size distribution and the displayed Figure CU-5 is the 2017–2024 average commercial loan-size chart.
  Date/Author: 2026-09-01 / Codex, revised after user supplied the current report.

- Decision: Use all FDIC SOD bank classes for the Figure 1 derivatives and national Figure 2.
  Rationale: This reproduces the values actually shown in the final report. The commercial-only `BKCLASS` filter would instead follow the methodology prose and the alternate `figreport` object in `bank_fig01_institutions_and_branches.R`.
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: Define the national geography as the 50 states plus the District of Columbia and exclude territories.
  Rationale: This matches the already validated national workbook, keeps FDIC/CRA/NCUA scopes consistent, and provides a reproducible meaning of “entire US.”
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: Treat “United States” as inclusive of Wisconsin in the CU comparison.
  Rationale: The task brief says “WI and the entire US.” This differs from the existing CU commercial-share figure, which uses “U.S. Excluding WI.” The inclusive national aggregate is the literal requested benchmark.
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: For each four-line CRA panel, index every geography/rurality series to its own base-year per-10,000 value.
  Rationale: This preserves the interpretation of the original Figures 8 and 9: each line shows percentage change from its own starting level. A common national baseline would instead compare levels and cause the Wisconsin series to be visually compressed.
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: Build one fixed RUCC lookup that uses 2023 first, 2013 second, and 2003 third, rather than switching the entire classification by analysis year.
  Rationale: This preserves the existing project convention of applying the current RUCC metro/nonmetro definition across the historical panel while using older vintages only to classify predecessor county FIPS codes absent from 2023. It eliminates every ordinary CRA mismatch without introducing the 149 and 127 urban/rural group changes that would occur at the 2003/2013 and 2013/2023 vintage transitions.
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: Recode legacy CRA county FIPS `51780` to successor county FIPS `51083` before the RUCC join.
  Rationale: Census county-change documentation states that South Boston independent city (`51780`) became part of Halifax County (`51083`) in 1995. The obsolete code nevertheless appears in staged CRA files for 2000–2002 and is absent from all three RUCC files. The successor mapping gives those records Halifax County's rural/nonmetro class and yields complete county coverage.
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: Normalize every CRA rurality series by the resident population living in that same geography-rurality subgroup.
  Rationale: This gives the direct interpretation requested by the user. For example, the Wisconsin rural series will be rural Wisconsin loans per 10,000 residents of Wisconsin counties classified rural/nonmetro, not rural loans per 10,000 total Wisconsin residents. Each series will then be indexed to its own year-2000 per-capita value.
  Date/Author: 2026-09-01 / User.

- Decision: Build the subgroup denominators from annual Census PEP/intercensal county resident-population estimates rather than ACS.
  Rationale: PEP supplies annual county point estimates across the full 2000–2023 window. The first ACS release covering every county is the 2005–2009 five-year product; successive all-county ACS observations are overlapping period estimates, so they would smooth and blur the annual movement being indexed. Use the final 2000–2010 county intercensal series for 2000–2009, the final 2010–2020 county intercensal series for 2010–2019, and the current 2020s county PEP series for 2020–2023. This is a source change from the labor-force/participation population proxy used in the original Figure 8/9 code, so reconciliation checks will distinguish numerator replication from expected denominator-driven index differences.
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: Keep all logic inside the new Quarto notebook, sourcing `_charlie_helpers.R` only for stable parsers and plotting style.
  Rationale: The requested deliverable is an additive lookbook. No existing production script needs to change, and no new processed-data artifact is required unless the chosen population solution warrants one and the user separately approves it.
  Date/Author: Approved 2026-09-01 / User and Codex.

- Decision: Do not update the README as part of this task.
  Rationale: Repository governance permits README changes only when explicitly requested. The notebook and this ExecPlan will document inputs, outputs, and methods.
  Date/Author: 2026-09-01 / Codex.

## Outcomes & Retrospective

Implementation is complete. The new Quarto notebook renders a 2.8 MB self-contained HTML with eight plots, two Figure-7-style tables, and compact audit tables for RUCC provenance, population classification, CRA replication, subgroup normalization, FDIC endpoints, and NCUA totals. All eligible population and CRA county records have RUCC classifications; the legacy South Boston rows are successor-mapped; Wisconsin CRA counts and volumes exactly reproduce the existing Figure 8 and 9 loaders before rurality splitting; Wisconsin FDIC endpoints reproduce 365 institutions/2,116 branches in 2000 and 193/1,661 in 2024; every index begins at 100 in 2000; and CU averages reproduce the existing Wisconsin ratio-of-totals series.

The final HTML was rendered twice without changes. Pandoc extraction confirmed eight embedded PNG plots, and direct visual inspection found no clipped titles, facet strips, legends, axes, captions, or bar labels after the CU label-format correction. The only render message is Quarto/Pandoc's non-failing deprecation warning for its internal self-contained alias; `embed-resources: true` produced the intended resource-embedded artifact. No existing source scripts, processed datasets, reports, or README files were changed.

## Context and Orientation

The task brief is `agent-docs/agent_context/2026_09_01_urbanrural_national_lookbook.md`. The source-of-truth report visual is `agent-docs/agent_context/docs/2026_small_biz_finance_report.docx`; the superseded `2026_08_03_final_report.docx` must not be used to interpret this task. The principal reference implementations are:

- `1_code/1_2_visualize/figs_charlie/bank_fig01_institutions_and_branches.R` for annual FDIC institution and branch counts.
- `1_code/1_2_visualize/figs_charlie/bank_fig02_institution_size_distribution.R` for the displayed 2024 institution-size buckets.
- `1_code/1_2_visualize/figs_charlie/bank_fig08_lending_frequency_growth.R` and `bank_fig09_lending_volume_growth.R` for the CRA indexes.
- `1_code/1_2_visualize/figs_charlie/cu_fig_cu5_avg_loan_size.R` for aggregate average credit-union commercial loan size.
- `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R` for local FDIC, CRA, NCUA, theme, and unit-conversion helpers.
- `1_code/workbooks/2026_08_24_cra_national_trends.qmd` for validated national CRA loading, national geography, and denominator audits.

RUCC is a county classification. This plan uses five-digit county FIPS as the canonical join key and derives two labels: `urban` for RUCC 1–3 and `rural` for RUCC 4–9. Build a unique lookup by taking the 2023 code when a FIPS appears in `Ruralurbancontinuumcodes2023.xlsx`, otherwise the 2013 code, otherwise the 2003 code. Recode obsolete South Boston FIPS `51780` to Halifax County `51083` before joining. Thus the 2023 classification remains fixed for current county FIPS across all historical years, while older vintages supply classifications only for predecessor county geographies that the CRA files retain.

## Planned Notebook Contents

The notebook will use one setup/audit section followed by two report-facing sections.

The “Urban/Rural Heterogeneity” section will contain:

1. Wisconsin branch counts by rurality, 2000–2024. For each year, filter FDIC branch location to `STALPBR == "WI"`, join `STCNTYBR` to RUCC, and count branch rows within urban and rural counties. Plot two lines with points.
2. Rural share of Wisconsin branch count, 2000–2024. For each year, divide rural branch rows by all classified Wisconsin branch rows and display a percentage line. Include endpoint values in a small audit table.
3. Rural Wisconsin Figure 7, 2023. Restrict CRA county aggregates to Wisconsin rural counties, then reproduce the displayed columns `Category`, `# of Loans`, `% of Loans`, `Volume`, `% of Volume`, and `Avg. Size`, including a total row. Shares are within rural Wisconsin, not shares of statewide lending.
4. Wisconsin urban/rural average credit-union commercial loan size, 2017–2024. Identify Wisconsin-headquartered credit unions from NCUA main-office records, classify each headquarters county using RUCC, join institution IDs to `FS220L.txt`, and calculate `sum(ACCT_475A1) / sum(ACCT_090A1)` separately by rurality and year. Plot grouped bars within each year. This is a ratio of group totals, matching the existing figure, not an unweighted mean of institution-level averages.

The “National Comparisons” section will contain:

5. National Figure 1, 2000–2024. Within branches located in the 50 states plus DC, plot annual distinct `CERT` institutions and branch-row counts using the same line/point structure as the displayed Wisconsin Figure 1. Because levels are far larger nationally, use data-driven y-axis limits rather than the Wisconsin 0–2,500 limit.
6. National Figure 2, 2024. Count eligible national branches per `CERT`, bin institutions into `1`, `2–5`, `6–10`, `11–20`, `21–50`, and `50+`, and plot institution counts with labels plus national mean, median, and total annotation.
7. National Figure 7, 2023. Aggregate all eligible U.S. county CRA records into the same three loan-size rows and total row used in the Wisconsin table. This table does not require RUCC because it is an all-U.S. benchmark.
8. Figure 8 extension: a vertical 3-by-1 facet layout for lending frequency. Facets are ordered `Under $100K`, `$100K–$250K`, and `$250K–$1M`. Every facet contains four annual lines: Wisconsin urban, Wisconsin rural, U.S. urban, and U.S. rural. Each line shows loans per 10,000 residents living in that same geography-rurality subgroup, indexed to its own year-2000 value, with a dashed reference at 100.
9. Figure 9 extension: the same 3-by-1 facet layout and four lines using nominal loan volume per 10,000 approved denominator residents. Do not inflation-adjust amounts because the source figure is nominal.
10. Wisconsin versus national average credit-union commercial loan size, 2017–2024. Use the same NCUA accounts and ratio-of-totals formula as item 4. The Wisconsin group contains credit unions headquartered in Wisconsin; the national group contains credit unions headquartered in the 50 states plus DC, including Wisconsin. Plot two grouped bars per year with dollar labels where legible.

Every figure/table section will include a concise method note and an audit object in the notebook. The notebook will not add interpretive claims beyond definitions and directly calculated descriptive endpoints.

## Data Contracts, Inputs, and Dependencies

The notebook will use R and Quarto only. Required packages are `tidyverse`, `readxl`, `scales`, and `knitr`, plus packages already loaded by `_charlie_helpers.R`. No Python implementation is permitted.

The RUCC inputs are `0_inputs/Ruralurbancontinuumcodes2023.xlsx`, `0_inputs/Ruralurbancontinuumcodes2013.xls`, and `0_inputs/Ruralurbancontinuumcodes2003.xls`. Normalize their county keys from `FIPS`, `FIPS`, and `FIPS Code` respectively to five-character strings and normalize their code columns to the common name `rucc`. Within each vintage, assert unique FIPS and integer RUCC values 1–9. Construct one precedence lookup with `coalesce(rucc_2023, rucc_2013, rucc_2003)`, retaining a `rucc_source_vintage` audit column. Before joining CRA data, replace county FIPS `51780` with `51083` and retain the original FIPS in a separate audit field. Assert every Wisconsin and national CRA county-year has exactly one RUCC match. Create `rurality` only after checking for missing RUCC; never allow `if_else()` or `case_when()` to convert missing RUCC into rural by default.

FDIC inputs are `0_inputs/data_charlie/FDIC/SOD_CustomDownload_ALL_YEAR_06_30.csv` for 2000–2024. Required fields are `CERT`, `STALPBR`, `STCNTYBR`, and `BKCLASS`. `load_fdic_sod()` is the canonical parser. A branch is one SOD row. An institution operating in a geography is one distinct `CERT` among branch rows located in that geography. The urban/rural branch figures classify the branch location, not the bank headquarters.

CRA inputs span three schemas and must follow the tested conversions in `1_code/workbooks/2026_08_24_cra_national_trends.qmd`:

- 2000–2004: `0_inputs/data_charlie/CRA/aggr/tract_YEAR.txt`; retain `report_level == 200`; amounts are thousands of dollars and must be multiplied by 1,000.
- 2005–2018: `0_inputs/data_charlie/CRA/cra_old/cra_YEAR.csv`; county FIPS is `fips`; amount fields are already dollars.
- 2019–2023: `0_inputs/data_charlie/CRA/YYexp_aggr/craYEAR_Aggr_A11.dat`; parse with `cra_fixed_widths` and `cra_fixed_names`; retain `Report_Level == "200"`; amounts are thousands of dollars and must be multiplied by 1,000.

All CRA eras must yield one harmonized county-year table with counts and amounts for the three existing buckets. The loader must retain county FIPS long enough to join RUCC; aggregating to state/nation before the join is invalid. The Figure 7 tables use 2023 only. The Figure 8/9 panels use the approved time window and denominator contract.

NCUA inputs are `Credit Union Branch Information.txt` and `FS220L.txt` under `0_inputs/data_charlie/NCUA/call-report-data-YEAR-12` for 2017–2024. Main offices satisfy `MainOffice == "Yes"`. Headquarters state is `PhysicalAddressStateCode`, headquarters county is normalized `PhysicalAddressCountyName`, and institution ID is `CU_NUMBER`. `ACCT_475A1` is the commercial-loan amount numerator and `ACCT_090A1` is the commercial-loan count denominator, matching `cu_fig_cu5_avg_loan_size.R`. Assert every included main-office `CU_NUMBER` is unique by year and audit unmatched financial-statement IDs.

The population denominator will be one annual Census resident-population estimate for each county or county equivalent. Stage the official source files additively under `0_inputs/data_charlie/Census/PEP_county_population/` before notebook rendering:

- 2000–2009: final 2000–2010 county intercensal estimates, using `POPESTIMATE2000` through `POPESTIMATE2009`.
- 2010–2019: final 2010–2020 county intercensal estimates, using the July 1 estimate for each year.
- 2020–2023: the latest completed 2020s PEP county series available at execution, using the July 1 estimate for each year and recording the Census vintage in the notebook.

Normalize state and county FIPS to fixed-width strings, retain only the 50 states plus DC, and assert one row per county-year. Join each native county geography to the fixed RUCC precedence lookup, then sum population to `year × state_fips × rurality`. Wisconsin denominators are the two state-FIPS-55 subgroup totals; national denominators are the corresponding sums across the 51 eligible state/DC geographies. County and county-equivalent changes must be audited explicitly: legacy South Boston records map to Halifax as already specified, while Connecticut's 2020s planning regions use their native 2023 RUCC entries and predecessor counties use the 2013 fallback. Because this is a population partition rather than a county-level numerator-denominator merge, both sides are aggregated to the requested state/national RUCC groups only after their own FIPS joins.

For every year, verify that urban plus rural county population equals the sum of all classified eligible county populations, and compare that sum to the published Wisconsin and U.S. PEP totals. Small differences caused only by excluded territories or documented county-equivalent treatment must be shown in an audit table and resolved before plotting. The existing Wisconsin files `0_inputs/data_charlie/co-est00int-01-55_raw.xls` and `0_inputs/data_charlie/co-est2024-pop-55_raw.xlsx` can validate parser design, but nationwide source files are still required. ACS and the RUCC files' decennial population columns must not be substituted for these annual denominators.

## Plan of Work

After user approval, stage the three official Census county-population source series under `0_inputs/data_charlie/Census/PEP_county_population/` and record each source URL, release/vintage, retrieval date, expected fields, and checksum in a small provenance file in the same directory. No county concordance download is planned; resolve predecessor codes through the staged RUCC vintages and the explicit South Boston successor mapping.

Create `1_code/workbooks/2026_09_01_urbanrural_national_lookbook.qmd` with embedded-resource HTML, a table of contents, hidden code by default, and `knitr::opts_knit$set(root.dir = project_root)`. Source `_charlie_helpers.R` and define all new helpers locally in the notebook so existing scripts are untouched.

Build the RUCC, geography, CRA, FDIC, NCUA, and population audit objects before producing figures. Use assertions to stop on duplicate keys, invalid RUCC codes, missing years, negative count/amount values, or unmatched geography. Show a compact RUCC provenance table with the number of county keys supplied by each vintage and the three South Boston successor-mapped years.

Construct the ten outputs in the order listed under `Planned Notebook Contents`. Preserve the existing `charlie_theme()` and report colors where possible. Use consistent geography colors across the two faceted CRA figures and consistent urban/rural colors across Wisconsin-only figures. Give the three facets a shared legend and fixed facet order. Do not force common y-axis limits between Figure 8 and Figure 9, but use a common scale within each figure so cross-facet differences remain visible.

End with a methods summary that states the geography, years, RUCC vintage, fixed-classification interpretation, denominator definition, nominal-dollar treatment, and any county exclusions. Do not hard-code headline results into prose; calculate them from notebook objects with inline R.

## Concrete Steps

Run commands from `/Users/indermajumdar/Research/Rural_Banking`.

1. Record final user approval in this plan and update `Progress` and `Decision Log`.
2. Add the official Census PEP/intercensal county population inputs under `0_inputs/data_charlie/Census/PEP_county_population/`. Do not add a separate county concordance.
3. Create the notebook according to this specification.
4. Render it with:

       QUARTO_R=/usr/local/bin/Rscript quarto render 1_code/workbooks/2026_09_01_urbanrural_national_lookbook.qmd

5. Confirm the rendered output exists:

       test -f 1_code/workbooks/2026_09_01_urbanrural_national_lookbook.html

6. Re-run the same render without changing inputs to confirm idempotence.

The render must not access the network. Any authorized external data acquisition must occur as a separately documented staging step before rendering.

## Validation and Acceptance

The implementation is accepted only if the Quarto command completes without error, produces a resource-embedded HTML, and a visual inspection confirms all ten outputs are legible without clipped titles, facet strips, legends, labels, or tables.

RUCC checks must confirm unique FIPS keys within each vintage, only codes 1–9, precedence of 2023 over 2013 over 2003, exact mapping of codes 1–3 to urban/metro and 4–9 to rural/nonmetro, and zero unmatched CRA county-years after the `51780` to `51083` successor mapping. Verify that the fixed-2023 code is used whenever available and that an older code is used only when the county FIPS is absent from every newer vintage. Also confirm zero unmatched Wisconsin FDIC county FIPS and zero unmatched Wisconsin NCUA headquarters after deterministic name normalization.

FDIC checks must confirm 25 years from 2000 through 2024, positive branch and institution counts, `urban branches + rural branches == all classified Wisconsin branches` in every year, rural shares between zero and one, and national counts at least as large as Wisconsin counts. Reproduce the displayed Wisconsin Figure 1 endpoints (365/2,116 in 2000 and 193/1,661 in 2024) under the proposed all-class definition before generalizing nationally.

Figure 2 checks must confirm each eligible national institution appears in exactly one bucket, bucket counts sum to the distinct national institution count, and the printed mean/median equal independent calculations from institution-level branch counts.

Figure 7 checks must confirm all three category rows plus a total row; category counts and volumes sum to totals; category shares sum to 100 percent within rounding tolerance; and average size equals amount divided by count. The rural-Wisconsin table must contain only RUCC 4–9 counties. The national table must cover the approved 50-states-plus-DC geography.

Figure 8 and 9 checks must confirm one row per year, bucket, and geography/rurality series; four lines in each of three facets; no internal missing years; all year-2000 indexes exactly 100; positive denominators; and identical raw Wisconsin totals to the existing loaders before rurality splitting. Amount unit conversions must match the three CRA eras exactly. Urban plus rural population must equal the sum of all classified eligible county populations in every year. Reconcile those county sums to separately published Wisconsin and U.S. PEP totals, document county-equivalent geography changes, and fail rather than silently dropping any unmatched population county. Reproduce the existing Figure 8/9 loan numerators exactly; do not require the normalized indexes to equal the existing labor-force/participation-proxy indexes because the approved denominator source is different.

NCUA checks must confirm eight years from 2017 through 2024, positive group loan counts, no duplicate main-office institution IDs, and exact reproduction of the existing Wisconsin average-loan-size series before splitting by rurality or adding the national comparison. The national amount/count totals must be at least the Wisconsin totals, and each plotted average must equal the displayed group numerator divided by denominator.

## Idempotence and Recovery

The notebook is read-only with respect to source inputs. Re-rendering may replace only its own same-basename HTML. It must not write JPEGs, CSVs, RDS files, or report assets unless a later approved revision explicitly adds them.

If the render fails, correct the notebook or the specifically named staged input and rerun the same command. No cleanup should be necessary. To abandon an incomplete implementation, remove only the new `.qmd` and its same-basename `.html`; do not alter shared helpers, existing workbooks, or source data.

## Artifacts and Notes

Core formulas are:

    rural branch share = rural branch rows / classified Wisconsin branch rows
    Figure 7 average size = bucket loan amount / bucket loan count
    CU average commercial loan size = sum(ACCT_475A1) / sum(ACCT_090A1)
    subgroup CRA per-10K value = bucket total / same geography-rurality resident population * 10,000
    CRA index = per-10K value / same-series base-year per-10K value * 100

The urban/rural terms must never be derived from county names, population alone, or a state-level proxy. They come only from the precedence RUCC lookup after a successful five-digit county-FIPS join (or, for NCUA Wisconsin headquarters, a validated county-name-to-FIPS lookup built from the same RUCC sources).

Plan created on 2026-09-01 after inspecting the task brief, report visuals, existing figure scripts and national workbook, staged inputs, RUCC definitions, join coverage, and denominator availability. Future revisions must append a dated note explaining what changed and why.

Plan updated on 2026-09-01 after the user supplied `2026_small_biz_finance_report.docx` and the 2003/2013 RUCC files. The revision replaces the superseded report reference, records the current visible figure identities, replaces the proposed external county concordance with a complete local RUCC-vintage fallback plus the Census-documented South Boston/Halifax successor mapping, and clarifies why the existing national normalization needs no new data while subgroup-specific urban/rural normalization would.

Plan updated on 2026-09-01 after the user selected subgroup-specific populations. The revision resolves each CRA denominator as the annual population living in the same Wisconsin/U.S. urban/rural subgroup, proposes Census PEP/intercensal annual county estimates instead of rolling ACS five-year estimates, restores the 2000 base year, and adds population-source, geography, and reconciliation audits.
