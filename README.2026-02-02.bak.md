# Rural_Banking
Measuring the impact of banking consolidation on rural lending composition, small business finance writ large. This project is currently descriptive/exploratory in nature

## Project Overview
This project evaluates how small business finance trends have evolved in Wisconsin. The goal is to build visuals and analysis similar to the CORI report in `agent-docs/agent_context/CORI_Rural-America-Struggle-Access-Private-Capital_May2025-compressed.pdf`.

## Key Data Sources
- CORI Form D data and HUD crosswalk via `1_code/1_0_ingest/CORI_formd.R`.
- Pitchbook Venture Monitor data in `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx` and `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx`.
- SBA 7(a) and 504 FOIA data from https://data.sba.gov/dataset/7-a-504-foia.
- County labor force annual averages in `0_inputs/CORI/labor_participation` (BLS LAUS county Excel files).

## Intermediate Outputs
- `1_code/1_1_transform/1_0_1_wi_descriptives.R`: builds Wisconsin descriptives intermediate `.rds` files used by `1_code/1_2_visualize`.
  Inputs: `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx`, `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx`, `0_inputs/bds2023_st_fa.csv`, `0_inputs/Ruralurbancontinuumcodes2023.xlsx`, `0_inputs/CORI/fips_participation.csv`, `0_inputs/CORI/labor_participation/*.xlsx`, `2_processed_data/formd_years/*.csv`.
  Outputs: `.rds` files in `2_processed_data/`, including `labor_force_county.rds` and `county_population_sum.rds` for Figure 8 normalization (see ExecPlan for the full list).
  Dependencies: `tidyverse`, `readxl`.

## Ingest Outputs
- `1_code/1_0_ingest/CORI_formd_new.R`: writes year-split Form D CSVs to `1_processed_data/formd_years/formd_YYYY.csv` (one file per year in `config$years`).

## Visualization Outputs
- `1_code/1_2_visualize/1_2_18_formd_dealsize_avg_fig18.R`: Form D deal size per average state (2016–2025 average).
  Inputs: `2_processed_data/vol_all.rds`, `2_processed_data/cnt_all.rds`.
  Output: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/18_formD_dealsize_avg.jpeg`.
  Dependencies: `tidyverse`, `scales`.
- `1_code/1_2_visualize/1_2_8_increment_sold_fig8.R`: Form D capital per 1M residents by Wisconsin county (CORI JSON numerator, county population proxy denominator).
  Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `2_processed_data/county_population_sum.rds`.
  Output: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/8_increment_sold_cumulative.jpeg`.
  Dependencies: `tidyverse`, `jsonlite`, `sf`, `scales`.
- `1_code/1_2_visualize/1_2_8b_increment_sold_percap_fig8b.R`: Form D capital per resident by Wisconsin county (variant for comparison).
  Inputs: `0_inputs/upstream/formd-interactive-map/src/data/formd_map.json`, `2_processed_data/county_population_sum.rds`.
  Output: `/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2/8b_increment_sold_cumulative.jpeg`.
  Dependencies: `tidyverse`, `jsonlite`, `sf`, `scales`.

## Figure Data Notes
- Figures 11, 12, 15, and 18 now use the CORI Form D interactive map JSON (since 2010) and may not reflect 2025 updates.
- Figure 15 includes per‑100,000 labor force normalization based on `0_inputs/CORI/fips_participation.csv` (years since 2010).
- Figure 8 uses CORI JSON totals for the numerator and county population estimated from county labor force with state participation rates; Figure 8b uses the same denominator but reports per‑resident values.

## Known Notes
- The CORI API workflow previously relied on `htmltab`, which was removed from CRAN; a workaround using GitHub/devtools may be required.
- Issuers vs. offerings logic and incremental amount raised calculations are outlined in `agent-docs/agent_context/1_Project Overview.md`.

## Legacy Code
Legacy scripts live in `1_code/legacy`. These scripts are retained for reference and may inform the new codebase.

If you touch legacy scripts, document:
- Purpose and expected outputs.
- Required inputs and assumptions.
- Whether the script still runs end-to-end or needs refactoring.

## Short-Term Focus
- Validate CORI ingest/cleaning steps and confirm no duplicate accession numbers.
- Align Wisconsin-focused visuals with the CORI report structure.
