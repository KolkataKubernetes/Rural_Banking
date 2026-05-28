# Build CRA-to-FDIC Local-HQ Crosswalk and Lending-Bucket Figure Spec (2026-05-16)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After this change, a contributor will be able to build a reproducible bridge from Community Reinvestment Act (CRA) lender records to FDIC Summary of Deposits (SOD) headquarters records, classify Wisconsin CRA lending as local or nonlocal, and render a figure showing the share of each small-business loan-size bucket attributable to locally headquartered banks. The implementation must be R-first, must rely on official FFIEC batch files rather than fragile browser scraping, and must leave an auditable paper trail in processed artifacts so the resulting report language can be defended.

The user-visible outcome is a new Wisconsin-focused dataset and figure pipeline that answers a question the current repo cannot answer: for a chosen year, and potentially for a year panel, what portion of CRA small-business lending in each loan-size bucket came from banks headquartered in the same county as the loans, elsewhere in Wisconsin, or outside Wisconsin.

## Progress

- [x] (2026-05-16 17:36Z) Reviewed `agent-docs/PLANS.md` and existing execplan patterns before drafting this spec.
- [x] (2026-05-16 17:36Z) Inspected the live FFIEC disclosure-reports webpage behavior through Safari and confirmed that the browser-accessible app is a server-rendered ASP.NET form inside `ffiec.gov/craadweb/DisRptMain.aspx`.
- [x] (2026-05-16 17:36Z) Confirmed that direct scripted requests to the disclosure-reports entry page are blocked by CAPTCHA/Cloudflare, which makes webpage scraping an unreliable production dependency.
- [x] (2026-05-16 17:36Z) Verified from the live webpage that a respondent-ID search resolves institution names in-browser, which makes the page useful as a manual QA tool for spot checks.
- [x] (2026-05-16 17:36Z) Verified from the official FFIEC CRA flat-file specifications that the annual `Transmittal Sheet` files include `Respondent ID`, `Agency Code`, `Respondent Name`, and `ID_RSSD`.
- [x] (2026-05-16 17:36Z) Verified from the official FFIEC CRA disclosure-file specifications that county-level disclosure rows include `Respondent ID`, `Agency Code`, `State`, `County`, `Report Level`, and the three loan-size buckets needed for small-business lending analysis.
- [x] (2026-05-16 17:36Z) Confirmed that the current local CRA files already used in `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R` are not sufficient for the target analysis because the lender-keyed local `area_YYYY.txt` files do not carry the three size buckets, while the bucketed local files do not carry lender identifiers.
- [x] (2026-05-16 17:36Z) Verified that `0_inputs/data_charlie/CRA/retail_loan_tables_2005/retail_loan_bank_attributes_2005.csv` already contains a one-year proof-of-concept bridge from CRA respondent IDs to `id_rssd`.
- [x] (2026-05-16 17:36Z) Drafted this initial spec plan in `agent-docs/execplans/2026_05_16_cra_fdic_local_hq_crosswalk_specplan.md`.
- [ ] Confirm with user which action scope the final figure should show: originations only, purchases only, or originations plus purchases.
- [ ] Confirm with user whether the headline visual should collapse to a binary `local vs nonlocal` split or retain the richer three-way breakdown `same county`, `other Wisconsin county`, `outside Wisconsin`.
- [ ] Implement the crosswalk and figure pipeline described below.

## Surprises & Discoveries

- Observation: The live FFIEC disclosure-reports page is not the best implementation path even though it can resolve institution names interactively.
  Evidence: Safari reached the in-iframe search form and returned `1-0000015820 AMERICAN BANK, N.A. (TX)` for respondent ID `0000015820`, but direct scripted requests to the same public entry page returned CAPTCHA/Cloudflare blocks.

- Observation: The official FFIEC flat-file system already contains the exact crosswalk fields the report needs, which makes scraping unnecessary for the main build.
  Evidence: The FFIEC `Transmittal Sheet (TS.DAT)` spec lists `Respondent ID`, `Agency Code`, `Respondent Name`, and `ID_RSSD` as standard fields.

- Observation: The needed lender-plus-bucket structure exists in official disclosure flat files, not in the reduced local CRA files currently used for the Charlie figure translations.
  Evidence: The FFIEC disclosure-file spec for county-originations (`D1-1`) includes `Respondent ID`, `Agency Code`, and the three amount buckets `<$100k`, `$100k-$250k`, and `$250k-$1m`, while the local `aggr/area_2010.txt` rows carry lender IDs but only total/small-business counts and volumes.

- Observation: A clean `respondent_id -> CERT` join is not defensible, but a `respondent_id + agency_code + year -> ID_RSSD -> SOD RSSDID` join should be.
  Evidence: The local 2005 bridge file maps all `Lender_in_CRA == Y` rows to nonmissing `id_rssd`, and SOD already includes `RSSDID` on headquarters rows.

## Decision Log

- Decision: Do not make the live disclosure-reports webpage a required production dependency.
  Rationale: It is reachable in a real browser but blocked under straightforward scripted access, which creates operational fragility and unnecessary anti-bot risk.
  Date/Author: 2026-05-16 / Codex

- Decision: Use official annual FFIEC `Transmittal Sheet` and `Disclosure Data` flat files as the authoritative CRA-side input for the crosswalk.
  Rationale: These official batch files expose the exact fields needed for an R-first, reproducible bridge without browser automation.
  Date/Author: 2026-05-16 / Codex

- Decision: Use `ID_RSSD` as the primary bridge key from CRA to FDIC SOD.
  Rationale: `ID_RSSD` is explicitly present in the transmittal-sheet specification and `RSSDID` is present in SOD. This is stronger and more auditable than name matching or direct `respondent_id -> CERT` guesses.
  Date/Author: 2026-05-16 / Codex

- Decision: Preserve `action_taken` or equivalent action scope in processed disclosure artifacts instead of hardcoding originations versus purchases at ingest time.
  Rationale: The final report visual has not yet fixed whether to show originations only or a broader scope, and this ambiguity affects measurement.
  Date/Author: 2026-05-16 / Codex

- Decision: Build the processed locality classification at the richest reasonable level: `same county`, `other Wisconsin county`, `outside Wisconsin`, and `unknown`.
  Rationale: This keeps the analytic artifact flexible. The final figure can later collapse categories if the user wants a simpler `local vs nonlocal` view.
  Date/Author: 2026-05-16 / Codex

- Decision: Keep implementation R-first and use Python only as a last-resort fallback for data acquisition or file parsing edge cases.
  Rationale: The project instructions prefer R, and the official flat-file structure is simple enough that base R plus `readr` should be sufficient.
  Date/Author: 2026-05-16 / Codex

## Outcomes & Retrospective

This plan resolves the main feasibility question. A reusable endpoint-based procedure through the live FFIEC search page is not the best production design. The correct build path is an R-first pipeline around annual FFIEC transmittal-sheet and disclosure flat files, with the live webpage reserved for manual spot-checks of unmatched institutions.

What remains unresolved is not the crosswalk mechanism. What remains unresolved is analytical presentation: which action scope belongs in the report figure, and whether the headline visual should show a binary or three-way locality split.

## Context and Orientation

The current repository can describe Wisconsin small-business lending by size bucket and bank headquarters by county, but it cannot connect those two facts at the lender level.

The relevant existing files are:

- `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R`
- `1_code/1_2_visualize/figs_charlie/bank_fig06_headquarters_map.R`
- `1_code/1_2_visualize/figs_charlie/bank_fig11_under100k_loans_map.R`
- `0_inputs/data_charlie/FDIC/SOD_CustomDownload_ALL_YYYY_06_30.csv`
- `0_inputs/data_charlie/CRA/aggr/area_YYYY.txt`
- `0_inputs/data_charlie/CRA/aggr/tract_YYYY.txt`
- `0_inputs/data_charlie/CRA/23exp_aggr/cra2023_Aggr_A11.dat`
- `0_inputs/data_charlie/CRA/retail_loan_tables_2005/retail_loan_bank_attributes_2005.csv`

The existing Charlie helper workflow uses CRA data in two disconnected ways.

First, it uses geography-level CRA files to build Wisconsin time series and county maps of loan-size buckets. For example, `load_cra_2023_county_aggregates()` in `1_code/1_2_visualize/figs_charlie/_charlie_helpers.R` reads `0_inputs/data_charlie/CRA/23exp_aggr/cra2023_Aggr_A11.dat`, which has bucketed lending counts and amounts but no lender identifier. That is sufficient for county totals and statewide sums, but not for lender-locality attribution.

Second, the repo uses FDIC SOD to identify bank headquarters. For example, `bank_fig06_headquarters_map.R` counts headquarters by filtering `BRNUM == 0` and `STALP == "WI"`. SOD gives the bank identity and headquarters county, but not CRA lending by bucket.

The crosswalk gap appears because the current local lender-keyed CRA file family is different. The `aggr/area_YYYY.txt` files include `respondent_id` and `agency_code`, but they do not include the three bucket columns needed for this figure. Conversely, the bucketed files used by the current Wisconsin county maps do not include the lender identifier.

The official FFIEC flat-file system solves that problem. In plain language:

- A `Transmittal Sheet` file is an annual institution roster submitted with CRA data. It carries the lender identifiers and the Federal Reserve `ID_RSSD`.
- A `Disclosure Data` file is an annual lender-by-geography lending file. It carries the same lender identifiers plus the small-business size buckets.

Those two official file families can be joined to SOD without relying on the live search webpage.

For this plan, define `locally headquartered bank` as follows at the processed-data level:

- `same_county`: the bank’s headquarters county code equals the county code on the CRA disclosure row.
- `other_wisconsin_county`: the bank’s headquarters state is Wisconsin, but the headquarters county differs from the county on the CRA disclosure row.
- `outside_wisconsin`: the bank’s headquarters state is not Wisconsin.
- `unknown`: the bank could not be matched from CRA to SOD for that year.

The final figure can collapse these categories later if the user wants a simpler presentation.

## Data Contracts, Inputs, and Dependencies

This plan assumes an R implementation using the packages already common in the repo or adjacent to them: `tidyverse`, `readr`, and `stringr`. No new heavy dependency is required. `zip` handling can use base R `unz()` or standard unzip behavior.

Existing local input contracts:

- `0_inputs/data_charlie/FDIC/SOD_CustomDownload_ALL_YYYY_06_30.csv`
  This is the annual SOD file already used in the repo. Required fields are `RSSDID`, `BRNUM`, `STALP`, `STCNTY`, `CNTYNAMB`, and `NAMEFULL`. The implementation must use `BRNUM == 0` as the headquarters row and treat `STCNTY` as the headquarters county FIPS code.

- `0_inputs/data_charlie/CRA/retail_loan_tables_2005/retail_loan_bank_attributes_2005.csv`
  This is not the main production input, but it is an important validation artifact. Required fields are `cra_respondent_id`, `cra_agency_code`, `cra_name`, and `id_rssd`.

New staged input contracts that must be created before implementation runs:

- `0_inputs/data_charlie/CRA/transmittal_raw/`
  This directory will hold annual FFIEC CRA transmittal-sheet files, either as extracted text files or as zip files with a documented extraction convention. Each annual file must expose the fixed-width fields:
  `Respondent ID`, `Agency Code`, `Activity Year`, `Respondent Name`, `Respondent State`, `Tax ID`, `ID_RSSD`, and `Assets`.

- `0_inputs/data_charlie/CRA/disclosure_raw/`
  This directory will hold annual FFIEC CRA disclosure-data files. The implementation must parse at least the small-business tables equivalent to county originations and county purchases. Required fields from the disclosure specification are:
  `Respondent ID`, `Agency Code`, `Activity Year`, `Loan Type`, `Action Taken Type`, `State`, `County`, `Report Level`, `Number/Amount < $100k`, `Number/Amount $100k-$250k`, `Number/Amount $250k-$1m`, and the small-business-revenue fields if preserved.

Processed output contracts to create:

- `2_processed_data/cra_transmittal_rssd_panel.rds`
  One row per `activity_year + agency_code + respondent_id`. Required columns: `activity_year`, `agency_code`, `respondent_id`, `respondent_name`, `respondent_state`, `id_rssd`, `assets`, and audit columns that flag duplicate or missing identifiers.

- `2_processed_data/cra_wi_disclosure_lender_county_panel.rds`
  One row per lender-county-action record retained for Wisconsin analysis. Required columns: `activity_year`, `agency_code`, `respondent_id`, `state_fips`, `county_fips`, `report_level`, `action_taken_type`, `loans_u100k_num`, `loans_u100k_amt`, `loans_100_250_num`, `loans_100_250_amt`, `loans_250_1m_num`, `loans_250_1m_amt`.

- `2_processed_data/cra_fdic_local_hq_bucket_panel.rds`
  The lender-county panel above after joining to SOD headquarters. Required columns: everything in the disclosure panel plus `id_rssd`, `hq_state`, `hq_county_fips`, `hq_county_name`, and `locality_class`.

- `2_processed_data/cra_fdic_local_hq_bucket_summary.csv`
  A summarized audit table suitable for plotting. Required columns: `activity_year`, `action_scope`, `bucket`, `locality_class`, `loan_count`, `loan_amount`, `share_of_bucket_count`, `share_of_bucket_amount`.

- A new figure output in the existing Charlie output directory, with the final filename chosen during implementation once the user confirms the exact presentation.

The implementation must remain additive. It must not overwrite current Charlie figure outputs unless the user explicitly requests replacement.

## Milestones

### Milestone 1: Stage the official CRA raw inputs and prove the bridge fields exist

At the end of this milestone, the repo will contain a documented local staging area for official FFIEC transmittal and disclosure flat files, plus a small parser proof that reads one year and emits the key bridge columns. This milestone de-risks the build by replacing guesswork about the webpage with audited flat-file fields.

Acceptance for this milestone is a one-year parsed transmittal sample that shows nonmissing `respondent_id`, `agency_code`, `respondent_name`, and `id_rssd`, and a one-year parsed disclosure sample that shows nonmissing lender identifiers plus the three size buckets.

### Milestone 2: Build the reusable CRA-to-SOD panel

At the end of this milestone, a contributor can run one R script and produce a processed annual panel that joins CRA disclosure lending rows to SOD headquarters rows through `ID_RSSD`. The panel must classify each lending row into `same_county`, `other_wisconsin_county`, `outside_wisconsin`, or `unknown`.

Acceptance for this milestone is a processed panel with unique keys, explicit unmatched counts, and a 2005 validation check against `retail_loan_bank_attributes_2005.csv`.

### Milestone 3: Summarize and render the report figure

At the end of this milestone, a contributor can generate a Wisconsin summary table and a report-ready figure that shows how lending in each bucket splits across locality classes. The figure script must read the processed summary artifact, not the raw files, so re-rendering is fast and auditable.

Acceptance for this milestone is a figure file plus a CSV summary whose bucket shares sum to one within each year-action bucket.

## Plan of Work

Create a new helper file at `1_code/1_2_visualize/figs_charlie/_cra_fdic_local_hq_helpers.R`. Keep the file self-contained and explicit, following the style already used in `_charlie_helpers.R`. This helper file will do four things.

First, it will parse the annual transmittal-sheet files. The parsing logic must be written directly in R using fixed-width widths taken from the FFIEC transmittal-sheet specification. Do not depend on the live webpage. The parser must normalize `respondent_id`, `agency_code`, and `id_rssd` as character strings first, then derive numeric versions only if needed for joins or audits.

Second, it will parse the annual disclosure-data files for the small-business county tables. The parser must keep the action scope and the bucket columns separate. It must retain only Wisconsin rows for downstream outputs, but it should do that after parsing rather than by hardcoding a Wisconsin-only substring reader. Use the disclosure-file specification fields so that the output contract is transparent and testable.

Third, it will join the parsed transmittal panel to the parsed disclosure panel on `activity_year + agency_code + respondent_id`, then join that result to SOD headquarters rows on `id_rssd == RSSDID` for the same year. The SOD join must be year-specific because headquarters can change over time.

Fourth, it will classify locality. The classification must compare the CRA lending county FIPS on the disclosure row to the SOD headquarters county FIPS on the headquarters row. This step is where `same_county`, `other_wisconsin_county`, `outside_wisconsin`, and `unknown` are assigned.

Create a new builder script at `1_code/1_2_visualize/figs_charlie/bank_build_local_hq_bucket_data.R`. This script will source `_charlie_helpers.R` and `_cra_fdic_local_hq_helpers.R`, build the processed artifacts listed above, and write both `.rds` and concise audit `.csv` outputs. The script must be idempotent and additive.

Create a new figure script at `1_code/1_2_visualize/figs_charlie/bank_fig_local_hq_bucket_shares.R`. This script will read `2_processed_data/cra_fdic_local_hq_bucket_summary.csv` and generate the final visual. The exact chart form may change after user confirmation, but the recommended default is a stacked bar chart with one bar per loan-size bucket and fill categories for `same county`, `other Wisconsin county`, and `outside Wisconsin`. If the user requests a binary local/nonlocal view, the plotting script should collapse classes at render time rather than rebuilding the processed data.

Do not wire this logic into the older aggregate-only CRA helpers. Keep the crosswalk workflow isolated so that the existing Charlie translations remain stable while this new addition is validated.

## Concrete Steps

Run from repository root: `/Users/indermajumdar/Research/Rural_Banking`.

Before implementation begins, stage the raw FFIEC files locally under:

- `0_inputs/data_charlie/CRA/transmittal_raw/`
- `0_inputs/data_charlie/CRA/disclosure_raw/`

If network use is authorized during implementation, an R helper may download them from the official FFIEC flat-files page. If network use is not authorized, stage them manually and document the local filenames the scripts expect.

Implementation run sequence:

1. Add `1_code/1_2_visualize/figs_charlie/_cra_fdic_local_hq_helpers.R`.
2. Add `1_code/1_2_visualize/figs_charlie/bank_build_local_hq_bucket_data.R`.
3. Add `1_code/1_2_visualize/figs_charlie/bank_fig_local_hq_bucket_shares.R`.
4. Run:

    Rscript 1_code/1_2_visualize/figs_charlie/bank_build_local_hq_bucket_data.R

5. Run:

    Rscript 1_code/1_2_visualize/figs_charlie/bank_fig_local_hq_bucket_shares.R

Expected short transcript excerpts:

    Writing 2_processed_data/cra_transmittal_rssd_panel.rds
    Writing 2_processed_data/cra_wi_disclosure_lender_county_panel.rds
    Writing 2_processed_data/cra_fdic_local_hq_bucket_panel.rds
    Writing 2_processed_data/cra_fdic_local_hq_bucket_summary.csv
    Saved -> .../bank_fig_local_hq_bucket_shares.jpeg

## Validation and Acceptance

Run these checks after implementation.

1. Parser sanity checks.

- The transmittal panel must have one unique row per `activity_year + agency_code + respondent_id`.
- The disclosure lender-county panel must have one unique row per retained key `activity_year + agency_code + respondent_id + state_fips + county_fips + report_level + action_taken_type`.
- The SOD headquarters slice for each year must have one unique row per `RSSDID` after filtering `BRNUM == 0`.

2. Crosswalk sanity checks.

- The join from transmittal to SOD must report match rates by year and by agency code.
- The 2005 respondent-to-RSSD mapping must be checked against `0_inputs/data_charlie/CRA/retail_loan_tables_2005/retail_loan_bank_attributes_2005.csv`. The expectation is that CRA lenders in that validation file should align closely with the transmittal-derived `id_rssd` values.
- Spot-check respondent ID `0000015820` for one year against the live FFIEC disclosure-search page as a manual QA check only. The scripted pipeline should not depend on the webpage, but the page may be used to confirm that the institution name resolved in the flat files is plausible.

3. Locality-class sanity checks.

- Within each `activity_year + action_scope + bucket`, the shares over all locality classes must sum to one for both loan counts and loan amounts, allowing only tiny floating-point error.
- `same_county` loans must only occur on rows where the matched SOD headquarters state is Wisconsin and the lending county FIPS matches the headquarters county FIPS exactly.
- `outside_wisconsin` rows must have a non-Wisconsin SOD headquarters state.

4. Figure acceptance checks.

- The final figure must render without error from the summarized CSV alone.
- The plotted bucket totals must match the summarized CSV totals exactly for the selected year and action scope.
- If the figure is binary `local vs nonlocal`, confirm that the binary aggregation equals `same_county` versus all other known classes.

## Idempotence and Recovery

The builder script must be safe to rerun. Re-running with unchanged raw inputs must reproduce the same processed outputs. If a join problem is discovered in one year, the contributor should be able to rerun only that year’s parse and then rerun the summary step without deleting unrelated artifacts.

If raw-file staging is incomplete, the builder script must fail early with a file-not-found message that names the missing year and directory. It must not silently drop missing years.

If an institution fails to match from transmittal to SOD, keep the row in the processed panel with `locality_class = "unknown"` and expose the unmatched count in an audit CSV. Do not discard unmatched records.

## Artifacts and Notes

Important evidence already established for this plan:

- The FFIEC transmittal-sheet specification includes `Respondent ID`, `Agency Code`, `Respondent Name`, and `ID_RSSD`.
- The FFIEC disclosure-file specification for small-business county lending includes both lender identifiers and the three loan-size buckets.
- The local 2005 validation file proves that a CRA-to-RSSD bridge is conceptually compatible with this repo’s data environment.
- The current local CRA `area_YYYY.txt` files are not enough for the final figure because they do not preserve the loan-size buckets alongside the lender identifier.

Recommended raw-input naming convention:

- `0_inputs/data_charlie/CRA/transmittal_raw/2010/`
- `0_inputs/data_charlie/CRA/disclosure_raw/2010/`

Store either the original zip plus an extracted text file, or only the extracted text file, but document the convention once and make the parser honor it consistently.

## Decision Requests

The implementation should pause for user confirmation on these questions if they remain unresolved at execution time.

1. Should the headline figure use:
   `originations only`, `purchases only`, or `originations + purchases`?

2. Should the headline figure show:
   `same county / other Wisconsin county / outside Wisconsin`, or a collapsed `local vs nonlocal` split?

3. Should the first report-ready figure default to the latest fully staged year, or should it target a specific report year such as `2023` for direct compatibility with the current Wisconsin county CRA maps?

Plan created on 2026-05-16 after inspecting the live FFIEC disclosure-reports webpage, confirming Cloudflare/CAPTCHA constraints on scripted access, and verifying from official FFIEC flat-file specifications that the transmittal and disclosure file families already provide the necessary fields for an R-first crosswalk to FDIC SOD.
