# Translate Charlie Figure Scripts Into Repository-Native R Visualizations

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a contributor should be able to run a Wisconsin small-business-finance figure pipeline entirely in R for the Charlie figure set, without depending on the departing collaborator's Python code. The visible outcome is a complete set of R scripts in `1_code/1_2_visualize/figs_charlie` that replicate the figure-specific Python scripts in `agent-docs/agent_context/docs/code_charlie`, consume only sanctioned local inputs under `0_inputs/data_charlie`, and write documented figure outputs in a consistent repository style.

This plan began as a spec-first document and now also records the implemented translation decisions, validation outcomes, and post-implementation revisions made during user review.

Resolved output contract for the implementation phase: bank scripts write JPEG outputs to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/bank_figs`; credit-union scripts write JPEG outputs to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/credit_union_figs`.

## Progress

- [x] (2026-05-11 13:42Z) Read `agent-docs/agent_context/2026_05_04_charlie_figs.md` and extracted the requested translation and integration scope.
- [x] (2026-05-11 13:42Z) Read `agent-docs/PLANS.md` and aligned this document to the repository ExecPlan requirements.
- [x] (2026-05-11 13:42Z) Located the actual Charlie R skeleton directory at `1_code/1_2_visualize/figs_charlie`; confirmed that five skeleton scripts already exist there.
- [x] (2026-05-11 13:42Z) Enumerated the Python source scripts in `agent-docs/agent_context/docs/code_charlie` and confirmed that the requested implementation surface is the `fig*.py` and `fig_cu*.py` files, excluding `run_all.py`.
- [x] (2026-05-11 13:42Z) Drafted this initial spec plan in `agent-docs/execplans/2026_05_11_charlie_figs_specplan.md`.
- [x] (2026-05-11 14:42Z) Locked output path and file format rules: bank figures save to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/bank_figs`, credit-union figures save to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/credit_union_figs`, and all outputs are `.jpeg`.
- [x] (2026-05-11 14:42Z) Locked script naming rule: use `bank_` and `cu_` prefixes followed by the original Python figure basename, such as `bank_fig02_branch_institution_ratio.R`.
- [x] (2026-05-11 14:42Z) Locked helper policy: one Charlie-specific helper is allowed if needed, but helper usage must be explicitly commented for readability in each calling script.
- [x] (2026-05-11 14:42Z) Locked validation default: strict replication is the default standard, with any sanctioned deviations documented explicitly.
- [x] (2026-05-11 14:42Z) Validated that `fig10` depends on a precomputed under-$100K series that is not written anywhere in the staged Python scripts and must be reconstructed during the R translation.
- [x] (2026-05-11 14:42Z) Validated that the staged county population workbooks are present locally and require explicit preprocessing to derive the `county` and `pop` fields Charlie’s Python logic assumes.
- [x] (2026-05-11 14:42Z) Resolved the sanctioned local geometry source for county map figures: use the staged Wisconsin county shapefile at `0_inputs/WI_CensusTL_Counties_2019/WI_CensusTL_Counties_2019.shp`.
- [x] (2026-05-11 15:47Z) Created explicit audit artifacts for county population preprocessing in `0_inputs/data_charlie`: `co-est00int-01-55_audit_long.csv` and `co-est2024-pop-55_audit_long.csv`.
- [x] (2026-05-11 15:47Z) User spot-checked the audit artifacts and confirmed the sampled values look correct enough to proceed with plan revision.
- [x] (2026-05-11 15:55Z) Resolved the CRA time-series denominator fallback: if `WIPOP.csv` remains unstaged, use annual Wisconsin population derived from `0_inputs/CORI/fips_participation.csv` as `Force / (Participation / 100)` and document the deviation from Charlie’s original file dependency.
- [x] (2026-05-11 16:00Z) Implemented shared helper file `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R` for local parsers, county geometry, county-pop audit inputs, and figure saving.
- [x] (2026-05-11 16:00Z) Created the translated bank figure scripts under `1_code/1_2_visualize/figs_charlie` and wrote their JPEG outputs to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/bank_figs`.
- [x] (2026-05-11 16:00Z) Created the translated credit-union figure scripts under `1_code/1_2_visualize/figs_charlie` and wrote their JPEG outputs to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/credit_union_figs`.
- [x] (2026-05-11 16:00Z) Validated that the translated scripts run with `/usr/local/bin/Rscript` and produce the expected output inventory, including the dual outputs from `bank_fig13_regional_comparison.R`.
- [x] (2026-05-11 16:00Z) Recorded the execution-time NCUA missing-file caveat for `cu_fig_cu03_institutions_branches_time.R`: branch files are absent for 2005-2009 and 2015.
- [x] (2026-05-11 17:20Z) Revised `bank_fig03_branches_per_10k_map.R` during user review to use fixed user-specified color buckets plus county and value labels.
- [x] (2026-05-11 17:35Z) Corrected the CRA early-year 250k-1M field mapping in the shared helper and restored `bank_fig08_lending_frequency_growth.R` and `bank_fig09_lending_volume_growth.R` to `2000 = 100` with all three groups present from 2000 onward.
- [x] (2026-05-11 17:45Z) Reworked `cu_fig_cu03_institutions_branches_time.R` into a side-by-side bar chart with a single shared axis and retained the explicit missing-year caveat.
- [x] (2026-05-11 18:05Z) Corrected `cu_fig_cu06_commercial_pct_assets.R` to use true total assets plus outstanding business-loan balances, extended the coverage to `2010-2024` with explicit `2015` omission, fixed the y-axis to `0%-15%`, and added a `U.S. Excluding WI` comparison line.

## Surprises & Discoveries

- Observation: The rough ask references `1_code/1_2_visualize_figs_charlie`, but the actual repository path is `1_code/1_2_visualize/figs_charlie`.
  Evidence: Directory search under `1_code` returned `1_code/1_2_visualize/figs_charlie`.

- Observation: Only five R skeletons currently exist, while the Python source directory contains twenty target figure scripts.
  Evidence: `1_code/1_2_visualize/figs_charlie` contains `fig01`, `fig02`, `fig02b`, `fig02c`, and `fig02d`; `agent-docs/agent_context/docs/code_charlie` contains fifteen `fig*.py` files and five `fig_cu*.py` files, plus `run_all.py`.

- Observation: Several Python map scripts fetch Census TIGER county geometry from the network.
  Evidence: `fig03_branches_per_10k_map.py`, `fig04_branch_change_map.py`, `fig05_institutions_per_10k_map.py`, `fig06_headquarters_map.py`, `fig11_under100k_loans_map.py`, `fig12_under100k_volume_map.py`, and `fig_cu04_branches_per_10k_wi_map.py` each call `gpd.read_file()` on Census URLs.

- Observation: The repo instructions for this project prohibit network fetches unless explicitly requested.
  Evidence: The root `AGENTS.md` states “Avoid network calls unless explicitly instructed; assume required data are already present locally unless told otherwise.”

- Observation: Some Python scripts depend on helper inputs whose local repository locations are not yet obvious from the initial scan.
  Evidence: quick repository searches did not immediately surface `WIPOP.csv`, `co-est2024-pop-55.xlsx`, `co-est00int-01-55.xls`, or `fig_under100k_data.csv` under `0_inputs`.

- Observation: At least one existing R skeleton name does not exactly match the corresponding Python basename.
  Evidence: the R skeleton is `1_code/1_2_visualize/figs_charlie/fig01_branches_institutions.R`, while the Python source is `agent-docs/agent_context/docs/code_charlie/fig01_institutions_and_branches.py`.

- Observation: `fig10_avg_loan_size.py` does not compute its own input CSV, and `fig08_lending_frequency_growth.py` does not write that CSV either.
  Evidence: `fig10_avg_loan_size.py` exits when `fig_under100k_data.csv` is absent, and repository search found no writer for `fig_under100k_data.csv`.

- Observation: The missing `fig10` intermediate is reconstructable from Charlie’s staged logic, but not from `fig08` alone.
  Evidence: `fig08_lending_frequency_growth.py` computes under-$100K loan counts by year, while `fig09_lending_volume_growth.py` computes under-$100K loan dollar volume by year; `fig10` needs the ratio of those two series.

- Observation: The staged 2024 county population workbook is readable but not yet in the simplified shape Charlie’s Python assumes.
  Evidence: `0_inputs/data_charlie/co-est2024-pop-55.xlsx` contains `Geographic Area` and year columns `2020` through `2024`; Charlie’s Python then expects derived `county` and `pop` columns.

- Observation: The staged 2000-2009 county population workbook requires header-aware parsing before a usable county/year table can be derived.
  Evidence: `0_inputs/data_charlie/co-est00int-01-55.xls` includes a metadata row and a two-row header, so direct `read_excel()` output does not expose final `county` and `pop` columns without preprocessing.

- Observation: The staged processed and raw county population workbooks are not byte-identical.
  Evidence: checksum comparison shows different MD5 values for `co-est00int-01-55.xls` versus `co-est00int-01-55_raw.xls`, and for `co-est2024-pop-55.xlsx` versus `co-est2024-pop-55_raw.xlsx`.

- Observation: A fully local Wisconsin county shapefile is now staged and can replace Charlie’s network TIGER fetches.
  Evidence: `0_inputs/WI_CensusTL_Counties_2019` contains `.shp`, `.shx`, `.dbf`, `.prj`, and related sidecar files.

- Observation: `county_population_sum.rds` is not an annual population table.
  Evidence: it contains only `county_fips` and `sum_population`, so it is a cumulative county denominator rather than a year-specific statewide population series.

- Observation: The edited `co-est00int-01-55.xls` workbook appears row-shifted relative to the raw Census download.
  Evidence: spot-checks showed implausible county values in the edited workbook, while `co-est00int-01-55_raw.xls` produced reasonable county populations such as `Brown,2009,246476`.

- Observation: The audit artifacts now provide a clean county population contract for execution.
  Evidence: `co-est00int-01-55_audit_long.csv` has 720 rows (`72 counties x 10 years`) and `co-est2024-pop-55_audit_long.csv` has 360 rows (`72 counties x 5 years`), both with schema `county, year, pop`.

- Observation: The default `Rscript` in this environment points to a broken Anaconda installation.
  Evidence: early validation failed with a missing `libreadline.6.2.dylib`; all successful execution used `/usr/local/bin/Rscript`.

- Observation: The staged NCUA branch inputs are missing more years than the original planning scan identified.
  Evidence: execution of `cu_fig_cu03_institutions_branches_time.R` showed missing branch files for 2005-2009 and 2015.

- Observation: Charlie's staged CRA Python scripts do not correctly populate the early `$250K-$1M` series even though the raw data are present.
  Evidence: the 2000-2004 CRA aggregate files store that bucket as `num_1mil` and `vol_1mil`, while Charlie's Python scripts reference `num_1M` and `vol_1M`.

- Observation: Charlie's staged `CU-06` Python script does not implement the intended "commercial loans as a percent of total assets" metric.
  Evidence: it only spans `2017-2024`, uses `ACCT_475A1` as the numerator, and falls back to `ACCT_025B1`, which the staged NCUA account descriptions identify as total loans and leases rather than total assets.

## Decision Log

- Decision: Treat this as a spec-plan drafting task only; do not begin translating the figure scripts in this phase.
  Rationale: the user explicitly asked to build the spec plan together and clarify ambiguities during planning.
  Date/Author: 2026-05-11 / Codex

- Decision: The implementation scope is the Python figure scripts prefixed `fig` and `fig_cu` in `agent-docs/agent_context/docs/code_charlie`, and excludes `run_all.py`.
  Rationale: the rough ask explicitly says to replicate all Python scripts prefixed `figXX` and `fig_cuXX`, with no R analogue for `run_all.py`.
  Date/Author: 2026-05-11 / Codex

- Decision: The plan must include validation as an explicit workstream even though the rough note does not separate it.
  Rationale: `agent-docs/PLANS.md` makes validation mandatory, and this task has multiple opportunities for silent drift in data loading, county matching, and output parity.
  Date/Author: 2026-05-11 / Codex

- Decision: The plan will assume R-only implementation using `tidyverse` and `ggplot2`, with repository-local data access.
  Rationale: the rough ask requests tidyverse/ggplot translations, and the root project instructions prohibit introducing other languages unless explicitly requested.
  Date/Author: 2026-05-11 / Codex

- Decision: Bank figure outputs will be written to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/bank_figs` and credit-union figure outputs will be written to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/credit_union_figs`, with `.jpeg` output format for all figures.
  Rationale: the user explicitly provided the destination directories and requested JPEG outputs.
  Date/Author: 2026-05-11 / User + Codex

- Decision: New script names will use `bank_` and `cu_` prefixes followed by the original Python basename.
  Rationale: the user wants the source figure identifier preserved while distinguishing bank and credit-union scripts in filenames.
  Date/Author: 2026-05-11 / User + Codex

- Decision: One Charlie-specific helper file is allowed if needed, but helper usage must be explicitly commented in each consuming script.
  Rationale: the user approved helper reuse for maintainability but wants readability preserved through rich comments.
  Date/Author: 2026-05-11 / User + Codex

- Decision: Default validation standard is strict replication.
  Rationale: the user explicitly preferred strict replication as the default standard.
  Date/Author: 2026-05-11 / User + Codex

- Decision: Keep Charlie’s hard-coded population values where they already exist during the first execution pass, then revisit replacement with staged local inputs after the R scripts run successfully.
  Rationale: the user wants first-pass replication against Charlie’s exact assumptions before normalization cleanup.
  Date/Author: 2026-05-11 / User + Codex

- Decision: Treat `call-report-data-2015-12` as a known missing dependency; proceed with implementation while flagging the resulting gap explicitly in the relevant credit-union script and in this plan before closeout.
  Rationale: the user instructed us to proceed now and to make the missing 2015 NCUA folder an explicit documented dependency.
  Date/Author: 2026-05-11 / User + Codex

- Decision: County map scripts will use the staged Wisconsin county shapefile at `0_inputs/WI_CensusTL_Counties_2019/WI_CensusTL_Counties_2019.shp`.
  Rationale: this preserves a fully local workflow and satisfies the project rule against unapproved network fetches.
  Date/Author: 2026-05-11 / User + Codex

- Decision: If `WIPOP.csv` remains absent, CRA per-10K time-series figures will use annual Wisconsin population derived from `0_inputs/CORI/fips_participation.csv` with `population = Force / (Participation / 100)`, and that deviation from Charlie’s original dependency will be documented.
  Rationale: `county_population_sum.rds` is a cumulative county denominator and is not appropriate for annual statewide CRA series, while `fips_participation.csv` already supports repo-native annual population normalization used elsewhere in this project.
  Date/Author: 2026-05-11 / User + Codex

- Decision: Execution uses `/usr/local/bin/Rscript` rather than the environment-default `Rscript`.
  Rationale: the default Anaconda-linked `Rscript` is not runnable in this environment because of a missing readline shared library.
  Date/Author: 2026-05-11 / Codex

- Decision: `cu_fig_cu06_commercial_pct_assets.R` will use `ACCT_010` from `fs220.txt` as the total-assets denominator for every staged year, `ACCT_400` as the outstanding business-loan numerator for `2010-2016`, and `ACCT_400T1` from `FS220L` as the outstanding commercial-loan numerator for `2017+`.
  Rationale: staged account descriptions show that `ACCT_025B1` is total loans and leases, not total assets, and `ACCT_475A1` is a granted/purchased-YTD measure rather than the intended outstanding-balance concept. The revised field mapping aligns the figure with the intended metric and the observed expected trend.
  Date/Author: 2026-05-11 / User + Codex

- Decision: `bank_fig08_lending_frequency_growth.R` and `bank_fig09_lending_volume_growth.R` will deliberately correct Charlie's early-year CRA 250k-1M column mapping so that all three series run from `2000` onward.
  Rationale: the raw staged data for `2000-2004` contain the third bucket under `num_1mil` and `vol_1mil`; the user explicitly approved fixing that mapping in the R implementation once the issue was confirmed.
  Date/Author: 2026-05-11 / User + Codex

- Decision: County population preprocessing will be treated as an explicit pre-execution audit step outside the main figure workflow, with reviewed artifacts written to `0_inputs/data_charlie`.
  Rationale: the user wanted reviewable population extracts before execution and asked that these artifacts live outside the workflow for audit purposes.
  Date/Author: 2026-05-11 / User + Codex

- Decision: County-map execution should read the reviewed audit CSVs directly instead of reparsing the original Census workbooks during each figure run.
  Rationale: this keeps execution simpler, makes the audited denominator inputs explicit, and avoids repeated workbook-specific parsing logic in multiple scripts.
  Date/Author: 2026-05-11 / User + Codex

- Decision: `bank_fig03_branches_per_10k_map.R` will use the user-specified fixed bucket ranges plus county and value labels rather than a pure Charlie-style minimalist map.
  Rationale: the user requested a more explicit county-by-county map output during post-implementation review.
  Date/Author: 2026-05-11 / User + Codex

- Decision: `cu_fig_cu03_institutions_branches_time.R` will use a side-by-side bar chart with a single shared axis from `0` to `800` rather than Charlie's dual-axis line chart.
  Rationale: the user requested a direct same-axis comparison for institutions and branches by year.
  Date/Author: 2026-05-11 / User + Codex

- Decision: `cu_fig_cu06_commercial_pct_assets.R` will include a comparison line for `U.S. Excluding WI`, constructed by summing all non-Wisconsin main-office credit unions each year under the same numerator/denominator mapping.
  Rationale: the user requested a national benchmark line using the staged local NCUA files without network dependencies.
  Date/Author: 2026-05-11 / User + Codex

## Outcomes & Retrospective

Implementation is complete for the Charlie figure translation pass, and this plan now reflects the post-implementation revisions made during user review. The repository contains a shared helper plus translated bank and credit-union R scripts under `1_code/1_2_visualize/figs_charlie`, the county-pop audit artifacts are part of the execution path for map figures, the CRA time-series scripts use the documented `fips_participation.csv` denominator fallback, and the later review cycle corrected both the CRA early-year 250k-1M mapping and the `CU-06` numerator/denominator logic.

Remaining caveats are now mostly data-stage or user-validation caveats rather than implementation blockers: NCUA branch files are absent for 2005-2009 and 2015, so affected CU time-series figures cannot yet be complete; several revised figures are being manually revalidated by the user after code-only updates; and `CU-06` depends on the stitched staged-field mapping (`ACCT_400` pre-2017 and `ACCT_400T1` post-2017`) because Charlie’s staged Python metric definition was not internally consistent.

## Context and Orientation

The source note for this plan is `agent-docs/agent_context/2026_05_04_charlie_figs.md`. That note asks for a repository-native R translation of Charlie's Python visualization scripts. The project already organizes work by stage: ingest scripts in `1_code/1_0_ingest`, transformations in `1_code/1_1_transform`, and visualizations in `1_code/1_2_visualize`.

The Charlie work sits inside the visualization stage. The existing R destination directory is `1_code/1_2_visualize/figs_charlie`. It currently contains five skeleton scripts:

- `1_code/1_2_visualize/figs_charlie/fig01_branches_institutions.R`
- `1_code/1_2_visualize/figs_charlie/fig02_branch_institution_ratio.R`
- `1_code/1_2_visualize/figs_charlie/fig02b_institution_size_distribution.R`
- `1_code/1_2_visualize/figs_charlie/fig02c_top5_banks_assets.R`
- `1_code/1_2_visualize/figs_charlie/fig02d_top5_banks_branches.R`

Each existing skeleton already establishes the required internal section order:

1. `Setup and configuration`
2. `Load Inputs`
3. `Construct Figure`
4. `Save Outputs`

The Python reference scripts live in `agent-docs/agent_context/docs/code_charlie`. They cover three local data domains under `0_inputs/data_charlie`:

- `0_inputs/data_charlie/FDIC`
- `0_inputs/data_charlie/CRA`
- `0_inputs/data_charlie/NCUA`

The current implementation surface is the following twenty figure scripts:

- `fig01_institutions_and_branches.py`
- `fig02_branch_institution_ratio.py`
- `fig02b_institution_size_distribution.py`
- `fig02c_top5_banks_assets.py`
- `fig02d_top5_banks_branches.py`
- `fig03_branches_per_10k_map.py`
- `fig04_branch_change_map.py`
- `fig05_institutions_per_10k_map.py`
- `fig06_headquarters_map.py`
- `fig08_lending_frequency_growth.py`
- `fig09_lending_volume_growth.py`
- `fig10_avg_loan_size.py`
- `fig11_under100k_loans_map.py`
- `fig12_under100k_volume_map.py`
- `fig13_regional_comparison.py`
- `fig_cu03_institutions_branches_time.py`
- `fig_cu04_branches_per_10k_wi_map.py`
- `fig_cu06_commercial_pct_assets.py`
- `fig_cu10_avg_loan_size.py`
- `fig_cu11_per_capita_lending.py`

Some of these scripts are simple one-file translations. Others imply shared logic. For example, the CRA time-series scripts read multiple file formats across years, and the county map scripts require county geometry plus county-name harmonization. The implementation plan must account for those shared needs without changing the project’s research scope.

Repository naming rule for this extension: each bank R script should be named `bank_<python-basename>.R`, and each credit-union R script should be named `cu_<python-basename>.R`. Examples: `bank_fig02_branch_institution_ratio.R` and `cu_fig_cu03_institutions_branches_time.R`.

## Data Contracts, Inputs, and Dependencies

Primary implementation dependencies:

- R packages: `tidyverse`, `ggplot2`, `readr`, `readxl`, and any additional R packages that are already standard in this repository and are strictly necessary for local file parsing or local geometry plotting.
- Source directory for Charlie-specific inputs: `0_inputs/data_charlie`.
- Reference scripts: `agent-docs/agent_context/docs/code_charlie/*.py`.
- Destination directory for R scripts: `1_code/1_2_visualize/figs_charlie`.
- Local county geometry source: `0_inputs/WI_CensusTL_Counties_2019/WI_CensusTL_Counties_2019.shp`.
- Reviewed county population audit artifacts:
  - `0_inputs/data_charlie/co-est00int-01-55_audit_long.csv`
  - `0_inputs/data_charlie/co-est2024-pop-55_audit_long.csv`
- Output directories:
  - `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/bank_figs`
  - `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/credit_union_figs`

Operational data contracts that the implementation must preserve:

1. Each target R script must clearly identify the Python source file it replicates in the header comment.
2. Each target R script must retain the four required internal sections already established in the skeletons.
3. Each target R script must read only local inputs. It must not fetch data, shapefiles, or lookup tables from the network.
4. Each target R script must write documented figure outputs and do so in a reproducible, rerunnable way.
5. The implementation must preserve the metric definitions used in the referenced Python scripts unless the plan explicitly records a sanctioned deviation.

Known dependency patterns by figure family:

- FDIC time-series figures (`fig01`, `fig02`) read annual `SOD_CustomDownload_ALL_YYYY_06_30.csv` files from `0_inputs/data_charlie/FDIC`.
- FDIC cross-sectional figures (`fig02b`, `fig02c`, `fig02d`, `fig06`) read one recent annual SOD file from `0_inputs/data_charlie/FDIC`.
- FDIC county maps (`fig03`, `fig04`, `fig05`, `fig06`) also require county geometry and county population denominators.
- CRA time-series figures (`fig08`, `fig09`) span multiple input formats across years and use Wisconsin population series for per-capita normalization.
- CRA output dependencies are linked: `fig10` expects precomputed under-$100K data in the Python version, but that CSV is not produced by `fig08` alone. The R translation should reconstruct the needed yearly input by combining the under-$100K count logic from `fig08` with the under-$100K amount logic from `fig09`, then compute `avg_size = amount / count`.
- CRA county maps (`fig11`, `fig12`) require 2023 county-level denominators and local county geometry.
- Regional comparison (`fig13`) produces two outputs from one source script and uses state-level denominators.
- NCUA scripts (`fig_cu03`, `fig_cu04`, `fig_cu06`, `fig_cu10`, `fig_cu11`) read a mix of `QCRYYYY12` folders, `call-report-data-YYYY-12` folders, and helper files such as `ncua_master_final.csv` and `lat_long_cu.csv`.
- County population workbook notes:
  - `0_inputs/data_charlie/co-est2024-pop-55_audit_long.csv` is the reviewed long-form county population artifact for years `2020` through `2024`, with schema `county, year, pop`.
  - `0_inputs/data_charlie/co-est00int-01-55_audit_long.csv` is the reviewed long-form county population artifact for years `2000` through `2009`, with schema `county, year, pop`.
  - Provenance note: the 2000-2009 audit artifact was derived from `0_inputs/data_charlie/co-est00int-01-55_raw.xls` because the edited `co-est00int-01-55.xls` appears row-shifted.
- Wisconsin population series note:
  - `WIPOP.csv` is still not staged locally.
  - Resolved fallback: for CRA per-10K time-series figures, derive annual Wisconsin population from `0_inputs/CORI/fips_participation.csv` using `population = Force / (Participation / 100)`.
  - This is a documented deviation from Charlie’s original `WIPOP.csv` dependency and applies only where `WIPOP.csv` remains unavailable.

## Plan of Work

Implementation should proceed in four milestones.

Milestone 1 covers repository scaffolding and contracts. Apply the locked naming convention, output directories, image format, helper policy, and local county geometry source; then resolve the remaining unresolved prerequisite around CRA population denominators. At the end of this milestone, the repository should have an unambiguous script inventory and output contract.

Milestone 2 covers the existing FDIC and NCUA non-map figures. Fill the five existing R skeletons and add the remaining non-map R scripts that translate the single-source Python figures. Reuse common styling and repeated loaders only in ways that preserve the mandatory four-section script layout. At the end of this milestone, all non-map Charlie scripts should run locally and save their expected outputs.

Milestone 3 covers the county map figures and other shared-data complexities. Replace the Python network shapefile fetches with a sanctioned local county geometry source, standardize county-name harmonization, and implement the FDIC, CRA, and NCUA county maps in R. At the end of this milestone, all county maps should render locally without network access.

The county map implementation should consume the reviewed county population audit CSVs directly. For the current Charlie figure set, the relevant years are `2009` for `fig04_branch_change_map` and `2023` for `fig03_branches_per_10k_map`, `fig05_institutions_per_10k_map`, `fig11_under100k_loans_map`, `fig12_under100k_volume_map`, and `fig_cu04_branches_per_10k_wi_map`.

Milestone 4 covers the CRA multi-year figures, shared intermediates, and validation. Implement the multi-format CRA loaders needed for `fig08`, `fig09`, `fig10`, `fig11`, `fig12`, and `fig13`, add any approved Charlie-specific helper or intermediate generation step, and run the validation suite described below. At the end of this milestone, the full Charlie figure set should run from local data with documented outputs and evidence-backed sanity checks.

## Decision Requests

No remaining implementation-blocking decision requests. The known missing `call-report-data-2015-12` dependency remains a documented execution caveat, not an unresolved design choice.

Execution-time caveat update: branch files are also absent for 2005-2009 in the staged NCUA inputs, so `cu_fig_cu03_institutions_branches_time.R` omits those years as well.

## Concrete Steps

When implementation begins, run all commands from repository root: `/Users/indermajumdar/Research/Rural_Banking`.

Expected execution pattern:

1. Edit or create the Charlie R scripts under `1_code/1_2_visualize/figs_charlie`, using the `bank_` and `cu_` naming prefixes defined above.
2. If approved, add one Charlie-specific helper script in the same directory or another user-approved repository path.
3. Run each translated script with `Rscript <path-to-script>`.
4. Record every output file written by every script.
5. Update this ExecPlan as milestones complete and as implementation decisions are finalized.

The implementation phase should avoid destructive overwrites. If an output file already exists and the user has not approved replacement, direct new outputs to a dated or Charlie-specific folder.

Execution was completed with `/usr/local/bin/Rscript`, not the default `Rscript`, because the default interpreter is not runnable in this environment.

## Validation and Acceptance

Validation must be explicit because the rough note did not separate it. The implementation will not be considered complete until all of the following are true.

Required command-level validation:

1. Every Charlie R script can be run from the repository root with `Rscript`.
2. No Charlie R script performs a network fetch.
3. Each script writes the documented output file or files to the sanctioned destination.

Required artifact checks:

1. Each script produces the expected number of figure files.
2. `fig13_regional_comparison.R` produces two distinct figure outputs, mirroring the dual-output behavior of the Python source.
3. All county map scripts produce Wisconsin county maps with no missing geometry caused by failed joins.
4. All output files are `.jpeg` and land in the user-specified bank or credit-union directory.

Required sanity checks:

1. Time-series scripts should show complete expected year coverage given the local files staged in `0_inputs/data_charlie`.
2. County-level maps should report or log the number of counties with matched denominators, so county join failures are visible.
3. For one figure in each family (FDIC, CRA, NCUA), compare a small set of summary values against the Python logic or against hand-checked local aggregates to detect metric drift.
4. The relevant credit-union time-series script must explicitly note the missing `call-report-data-2015-12` dependency if execution still skips 2015.

The plan should be updated during implementation with the exact validation commands used, the exact output paths written, and brief evidence snippets proving success.

Validation used the following execution pattern from repository root:

    /usr/local/bin/Rscript 1_code/1_2_visualize/figs_charlie/bank_fig01_institutions_and_branches.R
    ...
    /usr/local/bin/Rscript 1_code/1_2_visualize/figs_charlie/cu_fig_cu11_per_capita_lending.R

Observable output inventory:

- Bank outputs in `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/bank_figs`:
  `bank_fig01_institutions_and_branches.jpeg`, `bank_fig02_branch_institution_ratio.jpeg`, `bank_fig02b_institution_size_distribution.jpeg`, `bank_fig02c_top5_banks_assets.jpeg`, `bank_fig02d_top5_banks_branches.jpeg`, `bank_fig03_branches_per_10k_map.jpeg`, `bank_fig04_branch_change_map.jpeg`, `bank_fig05_institutions_per_10k_map.jpeg`, `bank_fig06_headquarters_map.jpeg`, `bank_fig08_lending_frequency_growth.jpeg`, `bank_fig09_lending_volume_growth.jpeg`, `bank_fig10_avg_loan_size.jpeg`, `bank_fig11_under100k_loans_map.jpeg`, `bank_fig12_under100k_volume_map.jpeg`, `bank_fig13a_regional_loans_per_10k.jpeg`, `bank_fig13b_regional_volume_per_10k.jpeg`.
- Credit-union outputs in `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/credit_union_figs`:
  `cu_fig_cu03_institutions_branches_time.jpeg`, `cu_fig_cu04_branches_per_10k_wi_map.jpeg`, `cu_fig_cu06_commercial_pct_assets.jpeg`, `cu_fig_cu10_avg_loan_size.jpeg`, `cu_fig_cu11_per_capita_lending.jpeg`.

Sanity-check evidence:

- Reviewed county population audit join for 2023: 72 joined county rows and 0 missing population values after joining `load_wi_counties()` to `co-est2024-pop-55_audit_long.csv`.
- `bank_fig13_regional_comparison.R` wrote two distinct outputs, matching the dual-output behavior of Charlie’s Python source.
- `cu_fig_cu03_institutions_branches_time.R` explicitly logs the missing staged branch years during execution.

## Idempotence and Recovery

The implementation should be safe to rerun. Script execution must not require deleting prior outputs or mutating raw inputs. If helpers or intermediate files are introduced, they must be written to clearly named repository paths and documented in this plan before use. If a script depends on a missing local prerequisite, the implementation should stop and record that missing dependency rather than silently falling back to a network source.

## Artifacts and Notes

Important planning artifacts identified during this draft:

- Source note: `agent-docs/agent_context/2026_05_04_charlie_figs.md`
- Python reference directory: `agent-docs/agent_context/docs/code_charlie`
- R destination directory: `1_code/1_2_visualize/figs_charlie`
- Charlie local input root: `0_inputs/data_charlie`
- Reviewed county population artifacts:
  - `0_inputs/data_charlie/co-est00int-01-55_audit_long.csv`
  - `0_inputs/data_charlie/co-est2024-pop-55_audit_long.csv`

Plan revision note: initial draft created on 2026-05-11 to convert the rough ask into a self-contained spec plan and to carve validation into its own explicit workstream.
Plan revision note: updated on 2026-05-11 after user clarification to lock output directories, JPEG output format, `bank_` / `cu_` naming, helper policy, strict-replication default, the documented missing `call-report-data-2015-12` dependency, the staged local Wisconsin county shapefile, and the validated notes on staged Census workbooks plus the reconstructable `fig10` intermediate.
Plan revision note: updated on 2026-05-11 after generating and user-reviewing explicit county population audit artifacts in long format, after recording that county-map execution should read those reviewed CSVs directly, and after locking `fips_participation.csv` as the CRA time-series denominator fallback when `WIPOP.csv` is unavailable.
Plan revision note: updated on 2026-05-11 after implementation and validation to record the actual script inventory, the output inventory, the `/usr/local/bin/Rscript` execution requirement, the staged-NCUA caveats, the corrected CRA early-year 250k-1M mapping, and the corrected `CU-06` commercial-loans-as-assets field mapping.
