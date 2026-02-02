This README was updated on 2026-02-02 by Codex.

# Project Overview

## Title

Rural_Banking

## Purpose and Scope

This repository constructs and maintains a reproducible data pipeline to assemble, clean, and visualize Wisconsin-focused small business finance data. The work is descriptive and exploratory in nature, and is designed to generate analysis-ready datasets and figures that align in structure, scope, definitions, and aggregation level with the CORI reference report. This repository does not introduce causal analysis, estimator selection, or interpretive claims beyond what is explicitly documented in source materials.

## Reference Report Alignment

Reference report: `agent-docs/agent_context/CORI_Rural-America-Struggle-Access-Private-Capital_May2025-compressed.pdf`.

“Alignment” means that the pipeline outputs and visuals are structured to mirror the report’s organization, scope boundaries, definitions, and aggregation level; it does not imply validation, endorsement, or analytical equivalence.

## Contacts

Primary contact:
- Name: Inder Majumdar
- ORCID (if available): https://orcid.org/0009-0004-1693-303X
- Institution: UW Madison
- Email: imajumdar@wisc.edu

## Funding

[Redacted at request]

## Dates and Geography

- Date(s) of data collection or coverage: Varies by source. Current processed Form D CSVs in `2_processed_data/formd_years/` span 2015–2024, and Pitchbook inputs include Q3/Q4 2025 summary files by filename.
- Geographic coverage (state/region/country; include counties if applicable): Wisconsin-focused outputs with national and Midwest comparisons; county-level coverage for Wisconsin where applicable.

# Repository Orientation

## High-Level Structure

This repository organizes inputs, R scripts, processed outputs, and project documentation in predictable folders.

- `0_inputs/`: External data inputs and local snapshots, organized by source.
- `1_code/`: R scripts by stage (ingest, transform, visualize) plus a `legacy/` subfolder.
- `2_processed_data/`: Analysis-ready and intermediate outputs (primarily `.rds` and year-split CSVs).
- `agent-docs/`: Project documentation, reference materials, and execution plans.

## Data Location and Pathing

`0_inputs/input_root.txt` provides a mounted-disk path for external inputs (`/Volumes/aae/users/imajumdar/Rural_Banking/0_inputs`). Scripts generally use repository-relative paths, but the following hardcoded paths are present and must be documented:

- `1_code/1_0_ingest/CORI_formd.R` reads from `/Volumes/aae/users/imajumdar/Rural_Banking/0_data/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx` and writes to `/Volumes/aae/users/imajumdar/Rural_Banking/1_processed_data/formd_2024.csv`.
- Scripts in `1_code/1_2_visualize/` write figures to `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2`.

# Data Sources and Access

## Primary Data Sources

- CORI SEC Form D data (via `dform` API and upstream snapshots)
  - Origin (local copy, agency, vendor): SEC Form D data accessed via CORI/dform.
  - Local path(s): `0_inputs/upstream/dform/`, `0_inputs/upstream/formd-interactive-map/`.
  - Ingest script(s): `1_code/1_0_ingest/CORI_formd.R`, `1_code/1_0_ingest/CORI_formd_new.R`.
  - Notes/constraints: API access may require network and package setup; some paths are hardcoded in `CORI_formd.R`.

- HUD ZIP-to-county crosswalk
  - Origin (local copy, agency, vendor): HUD.
  - Local path(s): `0_inputs/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx`.
  - Ingest script(s): `1_code/1_0_ingest/CORI_formd.R`, `1_code/1_0_ingest/CORI_formd_new.R`.
  - Notes/constraints: Used to map issuer ZIP codes to counties.

- Pitchbook Venture Monitor data
  - Origin (local copy, agency, vendor): Pitchbook/NVCA publication.
  - Local path(s): `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx`, `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx` (source file: `0_inputs/Pitchbook/Q3_2025_PitchBook-NVCA_Venture_Monitor_Summary_XLS_20370.xlsx`).
  - Ingest script(s): `1_code/1_1_transform/1_0_1_wi_descriptives.R`.
  - Notes/constraints: Summary pivot tables used for Wisconsin comparatives.

- SBA 7(a) and 504 FOIA data
  - Origin (local copy, agency, vendor): U.S. Small Business Administration (SBA) FOIA.
  - Local path(s): `0_inputs/SBA/7_A/`, `0_inputs/SBA/504/`.
  - Ingest script(s): None identified in current pipeline.
  - Notes/constraints: Staged in inputs; processing scripts not defined in current pipeline.

- BLS LAUS county labor force data
  - Origin (local copy, agency, vendor): Bureau of Labor Statistics (LAUS).
  - Local path(s): `0_inputs/CORI/labor_participation/`.
  - Ingest script(s): `1_code/1_1_transform/1_0_1_wi_descriptives.R`.
  - Notes/constraints: Used for county labor force and population normalization.

- Additional inputs referenced in transforms
  - `0_inputs/CORI/fips_participation.csv` (BLS source; TODO: verify provenance).
  - `0_inputs/bds2023_st_fa.csv` (U.S. Census Bureau Business Dynamics Statistics).
  - `0_inputs/Ruralurbancontinuumcodes2023.xlsx` (USDA ERS Rural-Urban Continuum Codes, 2013 vintage; reference link: `https://www.ers.usda.gov/data-products/rural-urban-continuum-codes`).

## Derived or Upstream Data

- `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json` and `states_outline.json` are upstream assets from the CORI interactive map repository.
- `0_inputs/links.md` lists upstream references (CORI formd-interactive-map and dform package repositories).

## Access, Licensing, and Restrictions

- Licenses or restrictions placed on the data: Not documented in this repository. TODO: confirm licensing for each source.
- Links to publications that cite or use the data: `agent-docs/agent_context/CORI_Rural-America-Struggle-Access-Private-Capital_May2025-compressed.pdf`.
- Links/relationships to ancillary data sets: `0_inputs/links.md`.
- Recommended citation for this dataset/repository: TODO.
- Agency provenance for public datasets:
  - SEC Form D data (SEC; accessed via CORI/dform workflow).
  - HUD ZIP-to-county crosswalk (HUD).
  - SBA 7(a) and 504 FOIA datasets (SBA).
  - LAUS county labor force data (BLS).
  - TODO: verify agency provenance for `0_inputs/CORI/fips_participation.csv` (currently noted as BLS).

# Pipeline Summary

## Pipeline Order (High-Level)

1. Ingest CORI Form D data and HUD crosswalk using `1_code/1_0_ingest/CORI_formd.R`.
2. Clean issuers and offerings; join on accession/year/quarter; compute incremental amounts raised (implemented in `1_code/1_0_ingest/CORI_formd.R` and `1_code/1_0_ingest/CORI_formd_new.R`).
3. Ingest Pitchbook Venture Monitor data from `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx` and `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx`.
4. Incorporate SBA 7(a) and 504 FOIA data from local copies staged in `0_inputs/SBA/`.
5. Produce Wisconsin-focused tables and visuals aligned in structure, definitions, and aggregation level with the CORI reference report.

## Inputs, Processing, and Outputs

Raw inputs in `0_inputs/` are transformed by `1_code/1_1_transform/1_0_1_wi_descriptives.R` into intermediate `.rds` datasets in `2_processed_data/`. Visualization scripts in `1_code/1_2_visualize/` read those intermediates and upstream CORI JSON data, and write figure files to an external output directory.

# Scripts and Outputs (Inventory)

## Ingest Scripts

- `1_code/1_0_ingest/CORI_formd.R`
  - Inputs: CORI Form D API (via `dform`), HUD crosswalk at `/Volumes/aae/users/imajumdar/Rural_Banking/0_data/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx`.
  - Outputs: `/Volumes/aae/users/imajumdar/Rural_Banking/1_processed_data/formd_2024.csv`.
  - Notes: Uses hardcoded paths and API access.

- `1_code/1_0_ingest/CORI_formd_new.R`
  - Inputs: CORI Form D API (via `dform`), `0_inputs/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx`, `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `0_inputs/CORI/fips_participation.csv`.
  - Outputs: `1_processed_data/formd_years/formd_YYYY.csv`, `1_processed_data/formd_qc_summary.csv`, `1_processed_data/formd_fig8_validation.csv`, `1_processed_data/formd_fig11_summary.csv`.
  - Notes: Output directory is configurable in-script (`config$output_dir`).

## Transform/Clean Scripts

- `1_code/1_1_transform/1_0_1_wi_descriptives.R`
  - Inputs: `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx`, `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx`, `0_inputs/CORI/fips_participation.csv`, `0_inputs/CORI/labor_participation/*.xlsx`, `0_inputs/bds2023_st_fa.csv`, `0_inputs/Ruralurbancontinuumcodes2023.xlsx`, `2_processed_data/formd_years/*.csv`.
  - Outputs: `.rds` files in `2_processed_data/` (see Output Files and Directories).
  - Notes: Refuses to overwrite outputs unless `overwrite <- TRUE`; stops if required inputs are missing.

## Visualization Scripts

- `1_code/1_2_visualize/1_2_1_vc_dealcount_fig1.R`
  - Inputs: `2_processed_data/count_ts_data.rds`, `0_inputs/CORI/fips_participation.csv`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/1_vc_dealcount.jpeg`.
  - Notes: Produces a Wisconsin vs. comparison-group time series of venture capital deal counts normalized by population. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_2_vc_dealvol_fig2.R`
  - Inputs: `2_processed_data/vol_ts_data.rds`, `0_inputs/CORI/fips_participation.csv`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/2_vc_capcommitted.jpeg`.
  - Notes: Produces a Wisconsin vs. comparison-group time series of venture capital capital committed normalized by population. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_3_vc_dealsize_fig3.R`
  - Inputs: `2_processed_data/count_ts_data.rds`, `2_processed_data/vol_ts_data.rds`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/3_vc_dealsize.jpeg`.
  - Notes: Produces a Wisconsin vs. comparison-group time series of average deal size derived from deal count and volume series. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_8_increment_sold_fig8.R`
  - Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `2_processed_data/county_population_sum.rds`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/8_increment_sold_cumulative.jpeg`.
  - Notes: Produces a Wisconsin county-level map or summary of cumulative Form D capital per 1M residents using CORI JSON totals and population proxies. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_8b_increment_sold_percap_fig8b.R`
  - Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `2_processed_data/county_population_sum.rds`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/8b_increment_sold_cumulative.jpeg`.
  - Notes: Produces a per-resident variant of the Wisconsin county Form D capital visualization for comparison to Figure 8. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_9_deals_cum_fig9.R`
  - Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/9_total_deals_cumulative.jpeg`.
  - Notes: Produces cumulative Form D deal counts by geography using CORI JSON data (e.g., state or county aggregates). Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_11_incremental_formD_perlf_fig11.R`
  - Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `0_inputs/CORI/fips_participation.csv`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/11_incremental_formD_per_lf_avg.jpeg`.
  - Notes: Produces average incremental Form D capital per labor force, comparing Wisconsin to other groups using CORI JSON and labor force participation inputs. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_12_dealcount_fig12.R`
  - Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `0_inputs/CORI/fips_participation.csv`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/12_formD_dealcount_avg.jpeg`.
  - Notes: Produces average Form D deal counts normalized by labor force, with Wisconsin compared to other groups. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_15_yearlyaverages_fig15.R`
  - Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `0_inputs/CORI/fips_participation.csv`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/15_formD_yearly_averages.jpeg`.
  - Notes: Produces yearly average Form D capital series by group and rural/metro classification using CORI JSON and participation data. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_16_yearly_avg_filing_fig16.R`
  - Inputs: `2_processed_data/formd_yearly_avg_filing.rds`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/16_formD_yearly_avg_filing.jpeg`.
  - Notes: Produces average Form D filing amounts by year and rural/metro classification from intermediate aggregates. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_17_fig17.R`
  - Inputs: `2_processed_data/formd_yearly_avg_raised_biz.rds`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/17_formD_yearly_avg_raised_biz.jpeg`.
  - Notes: Produces average Form D amount raised per business by year and rural/metro classification using intermediate aggregates. Uses a hardcoded output directory.

- `1_code/1_2_visualize/1_2_18_formd_dealsize_avg_fig18.R`
  - Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`.
  - Outputs: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/18_formD_dealsize_avg.jpeg`.
  - Notes: Produces average Form D deal size comparisons (Wisconsin vs. other groups) using CORI JSON totals. Uses a hardcoded output directory.

## Output Files and Directories

- `2_processed_data/`:
  - `2_processed_data/adj_all.rds`: Adjusted Form D series by RUCC group.
  - `2_processed_data/cnt_all.rds`: Dealcount series by RUCC group.
  - `2_processed_data/count_ts_data.rds`: Pitchbook dealcount time series aggregates.
  - `2_processed_data/county_population_sum.rds`: County population proxy from labor force participation.
  - `2_processed_data/dealsize_2024.rds`: 2024 deal size series.
  - `2_processed_data/dealsize_ts_data.rds`: Deal size time series aggregates.
  - `2_processed_data/formd_complete.rds`: Completed Form D series with RUCC grouping.
  - `2_processed_data/formd_data_US.rds`: Form D data filtered to U.S. ZIPs and constraints.
  - `2_processed_data/formd_wi_county.rds`: WI county aggregation of incremental Form D.
  - `2_processed_data/formd_wi_county_norm.rds`: WI county aggregation normalized by population.
  - `2_processed_data/formd_yearly_avg_filing.rds`: Average Form D filing amounts by year and RUCC type.
  - `2_processed_data/formd_yearly_avg_raised_biz.rds`: Average Form D amount raised per business by year.
  - `2_processed_data/formd_yearly_averages.rds`: Yearly averages by state group and RUCC type.
  - `2_processed_data/grp_all.rds`: BDS age-0 firm counts by group.
  - `2_processed_data/grp_all_lf.rds`: BDS age-0 firm counts normalized by labor force.
  - `2_processed_data/labor_force_county.rds`: County labor force (LAUS) processed.
  - `2_processed_data/metro_all.rds`: Metro deal size series by group.
  - `2_processed_data/rural_all.rds`: Rural deal size series by group.
  - `2_processed_data/vol_2024.rds`: 2024 deal volume series.
  - `2_processed_data/vol_all.rds`: Form D volume series by RUCC group.
  - `2_processed_data/vol_ts_data.rds`: Pitchbook deal volume time series aggregates.
  - `2_processed_data/formd_years/`: Year-split Form D CSVs (`formd_2015.csv`–`formd_2024.csv`).

- Other output locations (if outside repo):
  - `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/`: figure outputs from `1_code/1_2_visualize/`.
  - `/Volumes/aae/users/imajumdar/Rural_Banking/1_processed_data/`: Form D outputs from `1_code/1_0_ingest/CORI_formd.R` and `1_code/1_0_ingest/CORI_formd_new.R`.

- `legacy_processed_data/`:
  - Contains prior Form D year-split CSVs and summary outputs (`legacy_processed_data/formd_years/`, `legacy_processed_data/formd_qc_summary.csv`, `legacy_processed_data/formd_fig8_validation.csv`, `legacy_processed_data/formd_fig11_summary.csv`, `legacy_processed_data/formd_2014_2023_joined.csv`).

## TEMP/TEST Outputs

No TEMP/TEST scripts or outputs were identified in the repository.

# Data Dictionaries and Schemas

- `Data_Dict.qmd`: Working data dictionary source document.
- `Data_Dict.pdf`: Rendered data dictionary.

# Methodology and Processing Notes

## Data Collection / Generation

- CORI Form D data are accessed via the `dform` workflow and paired with HUD ZIP-to-county crosswalks to enable county-level mapping.
- Pitchbook Venture Monitor data are ingested from pre-extracted pivot tables in `0_inputs/Pitchbook/`.
- SBA FOIA data are staged in `0_inputs/SBA/` with no current processing scripts in the primary pipeline.

## Processing Steps

- `1_code/1_0_ingest/CORI_formd_new.R` standardizes issuer names, matches ZIPs to counties using HUD crosswalks, joins issuers and offerings, computes incremental amounts raised, and generates QC summaries.
- `1_code/1_1_transform/1_0_1_wi_descriptives.R` merges Pitchbook series, BDS counts, RUCC classifications, Form D year-splits, and labor-force participation data into intermediate `.rds` outputs used by visualization scripts.

## Software and Dependencies

- R version: Not specified in the repository.
- Packages (non-exhaustive): `tidyverse`, `readxl`, `readr`, `jsonlite`, `dform`, `httr`, `devtools`, `remotes`.

## Quality Assurance

- `1_code/1_0_ingest/CORI_formd_new.R` writes QC summaries (`formd_qc_summary.csv`, `formd_fig8_validation.csv`, `formd_fig11_summary.csv`).
- `1_code/1_1_transform/1_0_1_wi_descriptives.R` stops on missing required inputs and refuses to overwrite outputs unless explicitly allowed.

## People and Roles

- Inder Majumdar: primary author and maintainer.
- Tessa Conroy (UW-Madison): collaborator on the project.

# Reproducibility

This repository is conditionally reproducible given access to external input data referenced via `input_root.txt`.

## Known Issues and Limitations

- `1_code/1_0_ingest/CORI_formd.R` depends on packages that may require non-CRAN installation (e.g., `htmltab`/`dform`) and uses hardcoded paths.
- Visualization scripts write outputs to a hardcoded external directory.
- Some figures use the CORI formd-interactive-map JSON data, which may not reflect the latest updates relative to SEC data downloads.

# Versioning and Change Log

## Dataset Versions

- Are there multiple versions of the dataset?
  - TODO: document versioning policy and any dataset update cadence.

## Change Log

- 2026-02-02: README updated to new template; sections populated from repository inventory and documented hardcoded paths (mechanical update).
- 2026-02-02: Updated agency provenance notes for BDS, RUCC, and FIPS participation inputs; added USDA ERS reference link (mechanical update).

# Legacy Code

Legacy scripts live in `1_code/legacy` and are retained for reference:

- `1_code/legacy/SBA_7a_explore.R`
- `1_code/legacy/SBA_7a_explore_2.R`
- `1_code/legacy/pitchbook_explore.R`
- `1_code/legacy/WI_report_descriptives.R`

These scripts are not part of the current pipeline inventory and should be documented separately if reactivated.

# Appendix: Data-Specific Information

Variable-level data dictionaries are not included in the README. Refer to `Data_Dict.qmd` and `Data_Dict.pdf` for schema detail.

## Data-Specific Information for: 2_processed_data/*.rds

- Number of variables: See `Data_Dict.qmd`.
- Number of cases/rows: See `Data_Dict.qmd`.
- Variable list (name, description, units, value labels): See `Data_Dict.qmd`.
- Missing data codes: See `Data_Dict.qmd`.
- Specialized formats or abbreviations: See `Data_Dict.qmd`.
