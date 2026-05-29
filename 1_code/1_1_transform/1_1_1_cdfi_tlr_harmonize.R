#///////////////////////////////////////////////////////////////////////////////
#----                CDFI TLR Harmonization Intermediate                  ----
# File name:  1_1_1_cdfi_tlr_harmonize.R
# Author:     Codex
# Created:    2026-05-28
# Purpose:    Harmonize staged CDFI transaction-level lending releases into
#             reusable processed outputs for downstream descriptive work.
#///////////////////////////////////////////////////////////////////////////////

suppressPackageStartupMessages({
  library(tidyverse)
})

overwrite <- FALSE

# The raw CDFI inputs are staged in multiple vintages with materially different
# schemas. Keep every path explicit here so a reader can see the exact backbone
# used for the first-pass comparable series.
paths <- list(
  historical_tlr = file.path(
    "0_inputs", "2017_CDFI",
    c(
      "releaseTLR_fy03_15(1of5).csv",
      "releaseTLR_fy03_15(2of5).csv",
      "releaseTLR_fy03_15(3of5).csv",
      "releaseTLR_fy03_15(4of5).csv",
      "releaseTLR_fy03_15(5of5).csv"
    )
  ),
  annual_2018 = file.path("0_inputs", "2018_CDFI", "releaseTLR_fy18.csv"),
  annual_2019 = file.path("0_inputs", "2019_CDFI", "releaseTLR_fy19.csv"),
  annual_2020 = file.path("0_inputs", "2020_CDFI", "releaseTLR_fy20.csv"),
  annual_2021 = file.path("0_inputs", "2021_CDFI", "releaseTLR_fy21.csv"),
  annual_2022 = file.path("0_inputs", "2022_CDFI", "tlr_fy22_release.csv"),
  historical_ilr = file.path("0_inputs", "2017_CDFI", "releaseILR_fy03_15(1of1).csv")
)

output_dir <- "2_processed_data"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

stopifnot(
  all(file.exists(paths$historical_tlr)),
  file.exists(paths$annual_2018),
  file.exists(paths$annual_2019),
  file.exists(paths$annual_2020),
  file.exists(paths$annual_2021),
  file.exists(paths$annual_2022),
  file.exists(paths$historical_ilr)
)

resolve_output_path <- function(filename) {
  out_path <- file.path(output_dir, filename)
  if (overwrite || !file.exists(out_path)) {
    return(out_path)
  }

  # By default we do not overwrite an existing processed artifact. Instead we
  # create a TEMP variant that can be compared before any canonical replacement.
  sub("(\\.[^.]+)$", "_TEMP\\1", out_path)
}

normalize_missing <- function(x) {
  # The staged files use several different text markers for missing values.
  # Converting them up front keeps the downstream logic simpler.
  x <- stringr::str_trim(as.character(x))
  x[x %in% c("", "NA", "NULL", "NONE", "N/A", "Do Not Know")] <- NA_character_
  x
}

parse_dmy_monyear <- function(x) {
  # Most older date fields use strings like 15-Mar-18. Some rows expand the
  # year to four digits, so we try the common two-digit form first and then
  # patch the leftovers with a four-digit parse.
  x <- normalize_missing(x)

  out <- suppressWarnings(as.Date(x, format = "%d-%b-%y"))
  needs_four_digit <- is.na(out) & !is.na(x)
  out[needs_four_digit] <- suppressWarnings(as.Date(
    x[needs_four_digit],
    format = "%d-%b-%Y"
  ))

  out
}

parse_iso_date <- function(x) {
  # The 2022 release switched to ISO-style dates, so it gets a separate parser.
  x <- normalize_missing(x)
  suppressWarnings(as.Date(x))
}

normalize_geo_digits <- function(x) {
  # Geography arrives as tract-like FIPS strings, but some exports dropped a
  # leading zero. Strip non-digits, then restore 10-digit values to width 11
  # before deriving state and county identifiers.
  x <- normalize_missing(x)
  digits <- stringr::str_replace_all(dplyr::coalesce(x, ""), "[^0-9]", "")
  digits[digits == ""] <- NA_character_

  dplyr::case_when(
    is.na(digits) ~ NA_character_,
    nchar(digits) == 10L ~ stringr::str_pad(digits, width = 11, side = "left", pad = "0"),
    TRUE ~ digits
  )
}

derive_state_fips <- function(x) {
  dplyr::if_else(!is.na(x) & nchar(x) >= 2L, substr(x, 1L, 2L), NA_character_)
}

derive_county_fips <- function(x) {
  dplyr::if_else(!is.na(x) & nchar(x) >= 5L, substr(x, 1L, 5L), NA_character_)
}

read_historical_tlr <- function(path) {
  # The historical extract is pooled across years and does not expose a clean
  # report-year field. We therefore leave report_year missing here and recover
  # year later from the observed transaction date.
  readr::read_csv(
    path,
    col_select = c(
      org_id, trans_id, originalamount, projectfipscode_2000, projectfipscode_2010,
      investeetype, dateclosed, purpose, transactiontype, naicscode
    ),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    transmute(
      source_file = basename(path),
      source_family = "historical_tlr_2003_2015",
      source_release = "2017_CDFI_historical_extract",
      report_year = NA_integer_,
      report_year_raw = NA_character_,
      org_id = normalize_missing(org_id),
      trans_id = normalize_missing(trans_id),
      original_amount = suppressWarnings(as.numeric(normalize_missing(originalamount))),
      raw_project_fips_2000 = normalize_missing(projectfipscode_2000),
      raw_project_fips_2010 = normalize_missing(projectfipscode_2010),
      investee_type = normalize_missing(investeetype),
      transaction_date_raw = normalize_missing(dateclosed),
      transaction_date = parse_dmy_monyear(dateclosed),
      purpose = normalize_missing(purpose),
      transaction_type = normalize_missing(transactiontype),
      industry_raw = normalize_missing(naicscode)
    )
}

read_annual_tlr <- function(path, release_label) {
  # The 2018-2021 annual releases are structurally similar enough that one
  # reader can standardize them into the same canonical columns.
  readr::read_csv(
    path,
    col_select = c(
      org_id, trans_id, fiscalyear, originalamount, projectfipscode_2010,
      investeetype, dateclosed, purpose, transactiontype, naicscode
    ),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    transmute(
      source_file = basename(path),
      source_family = "annual_tlr_2018_2021",
      source_release = release_label,
      report_year = suppressWarnings(as.integer(normalize_missing(fiscalyear))),
      report_year_raw = normalize_missing(fiscalyear),
      org_id = normalize_missing(org_id),
      trans_id = normalize_missing(trans_id),
      original_amount = suppressWarnings(as.numeric(normalize_missing(originalamount))),
      raw_project_fips_2000 = NA_character_,
      raw_project_fips_2010 = normalize_missing(projectfipscode_2010),
      investee_type = normalize_missing(investeetype),
      transaction_date_raw = normalize_missing(dateclosed),
      transaction_date = parse_dmy_monyear(dateclosed),
      purpose = normalize_missing(purpose),
      transaction_type = normalize_missing(transactiontype),
      industry_raw = normalize_missing(naicscode)
    )
}

read_2022_tlr <- function(path) {
  # The 2022 release renamed several fields, including the year and date
  # variables, so it needs its own mapping block.
  readr::read_csv(
    path,
    col_select = c(
      org_id, trans_id, tlr_submission_year__c, original_loan_investment_amount_,
      fipscode_2010, investee_type__c, date_originated__c, purpose__c,
      transaction_type__c, naics_name
    ),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    transmute(
      source_file = basename(path),
      source_family = "annual_tlr_2022",
      source_release = "2022_CDFI_tlr_release",
      report_year = suppressWarnings(as.integer(normalize_missing(tlr_submission_year__c))),
      report_year_raw = normalize_missing(tlr_submission_year__c),
      org_id = normalize_missing(org_id),
      trans_id = normalize_missing(trans_id),
      original_amount = suppressWarnings(as.numeric(normalize_missing(original_loan_investment_amount_))),
      raw_project_fips_2000 = NA_character_,
      raw_project_fips_2010 = normalize_missing(fipscode_2010),
      investee_type = normalize_missing(investee_type__c),
      transaction_date_raw = normalize_missing(date_originated__c),
      transaction_date = parse_iso_date(date_originated__c),
      purpose = normalize_missing(purpose__c),
      transaction_type = normalize_missing(transaction_type__c),
      industry_raw = normalize_missing(naics_name)
    )
}

historical_ilr_years <- readr::read_csv(
  paths$historical_ilr,
  col_select = c(fiscalyear),
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE,
  progress = FALSE
) |>
  mutate(fiscalyear = suppressWarnings(as.integer(normalize_missing(fiscalyear)))) |>
  filter(!is.na(fiscalyear)) |>
  distinct(fiscalyear) |>
  arrange(fiscalyear) |>
  pull(fiscalyear)

# The ILR file is not part of the main processed output, but it is useful as a
# check on the intended historical reporting window: 2003 through 2015.
historical_tlr <- purrr::map_dfr(paths$historical_tlr, read_historical_tlr)
annual_tlr <- bind_rows(
  read_annual_tlr(paths$annual_2018, "2018_CDFI_tlr_release"),
  read_annual_tlr(paths$annual_2019, "2019_CDFI_tlr_release"),
  read_annual_tlr(paths$annual_2020, "2020_CDFI_tlr_release"),
  read_annual_tlr(paths$annual_2021, "2021_CDFI_tlr_release"),
  read_2022_tlr(paths$annual_2022)
)

tlr_raw <- bind_rows(historical_tlr, annual_tlr) |>
  mutate(
    # Keep both notions of time. transaction_year comes from an observed loan
    # date; report_year comes from the annual release when available. The
    # first-pass analysis_year uses transaction_year first and only falls back
    # to report_year when the observed date is missing.
    transaction_year = as.integer(format(transaction_date, "%Y")),
    analysis_year = dplyr::coalesce(transaction_year, report_year),
    analysis_year_source = dplyr::case_when(
      !is.na(transaction_year) ~ "transaction_date",
      !is.na(report_year) ~ "report_year_fallback",
      TRUE ~ "missing"
    ),
    project_fips_2000 = normalize_geo_digits(raw_project_fips_2000),
    project_fips_2010 = normalize_geo_digits(raw_project_fips_2010),
    # Prefer the 2010 geography when it exists because that is the only tract
    # version available in the later annual files.
    project_fips_preferred = dplyr::coalesce(project_fips_2010, project_fips_2000),
    state_fips = derive_state_fips(project_fips_preferred),
    county_fips = derive_county_fips(project_fips_preferred),
    investee_type = stringr::str_to_upper(investee_type),
    is_business = investee_type == "BUS",
    is_usable_amount = !is.na(original_amount) & original_amount > 0,
    is_usable_state_fips = !is.na(state_fips) & stringr::str_detect(state_fips, "^[0-9]{2}$"),
    is_usable_county_fips = !is.na(county_fips) & stringr::str_detect(county_fips, "^[0-9]{5}$"),
    is_usable_industry = !is.na(industry_raw)
  )

excluded_summary <- tlr_raw |>
  summarise(
    total_rows = n(),
    rows_missing_analysis_year = sum(is.na(analysis_year)),
    rows_before_2003 = sum(!is.na(analysis_year) & analysis_year < 2003),
    rows_after_2022 = sum(!is.na(analysis_year) & analysis_year > 2022),
    historical_rows_before_2003 = sum(
      source_family == "historical_tlr_2003_2015" &
        !is.na(analysis_year) &
        analysis_year < 2003
    )
  )

cdfi_tlr_harmonized <- tlr_raw |>
  filter(!is.na(analysis_year), analysis_year >= 2003, analysis_year <= 2022) |>
  mutate(
    # org_id + trans_id is not stable across annual releases. Include a year
    # component in the event key so reused identifiers from later submissions
    # do not collapse into a single faux transaction.
    event_year_for_key = dplyr::coalesce(report_year, analysis_year),
    event_key = paste(event_year_for_key, org_id, trans_id, sep = "__")
  ) |>
  group_by(event_key) |>
  mutate(
    event_row_count = n(),
    state_geo_row_count = sum(is_usable_state_fips, na.rm = TRUE),
    county_geo_row_count = sum(is_usable_county_fips, na.rm = TRUE),
    is_multi_geo_event = event_row_count > 1L,
    # Some events appear on multiple geography rows. Keep those rows and create
    # equal-split weights so later state and county summaries can use explicit
    # allocated totals rather than silently dropping duplicate geographies.
    allocation_weight_state = dplyr::if_else(
      is_usable_state_fips & state_geo_row_count > 0L,
      1 / state_geo_row_count,
      NA_real_
    ),
    allocation_weight_county = dplyr::if_else(
      is_usable_county_fips & county_geo_row_count > 0L,
      1 / county_geo_row_count,
      NA_real_
    ),
    allocated_amount_state = dplyr::if_else(
      is_usable_amount & !is.na(allocation_weight_state),
      original_amount * allocation_weight_state,
      NA_real_
    ),
    allocated_amount_county = dplyr::if_else(
      is_usable_amount & !is.na(allocation_weight_county),
      original_amount * allocation_weight_county,
      NA_real_
    ),
    allocated_loan_count_state = allocation_weight_state,
    allocated_loan_count_county = allocation_weight_county
  ) |>
  ungroup() |>
  select(
    source_file, source_family, source_release,
    report_year, report_year_raw,
    transaction_date_raw, transaction_date, transaction_year,
    analysis_year, analysis_year_source,
    event_year_for_key, event_key, event_row_count, state_geo_row_count,
    county_geo_row_count, is_multi_geo_event,
    org_id, trans_id, original_amount,
    raw_project_fips_2000, raw_project_fips_2010,
    project_fips_2000, project_fips_2010, project_fips_preferred,
    state_fips, county_fips,
    investee_type, is_business,
    purpose, transaction_type, industry_raw,
    is_usable_amount, is_usable_state_fips, is_usable_county_fips, is_usable_industry,
    allocation_weight_state, allocation_weight_county,
    allocated_amount_state, allocated_amount_county,
    allocated_loan_count_state, allocated_loan_count_county
  )

cdfi_field_coverage_by_year <- cdfi_tlr_harmonized |>
  group_by(analysis_year) |>
  summarise(
    row_count = n(),
    event_count = n_distinct(event_key),
    business_row_count = sum(is_business, na.rm = TRUE),
    business_event_count = n_distinct(event_key[is_business]),
    share_usable_amount = mean(is_usable_amount, na.rm = TRUE),
    share_usable_state_fips = mean(is_usable_state_fips, na.rm = TRUE),
    share_usable_county_fips = mean(is_usable_county_fips, na.rm = TRUE),
    share_nonmissing_investee_type = mean(!is.na(investee_type), na.rm = TRUE),
    share_business_investee = mean(is_business, na.rm = TRUE),
    share_usable_industry = mean(is_usable_industry, na.rm = TRUE),
    share_transaction_year_observed = mean(!is.na(transaction_year), na.rm = TRUE),
    share_analysis_year_from_report_fallback = mean(
      analysis_year_source == "report_year_fallback",
      na.rm = TRUE
    ),
    multi_geo_event_share = mean(is_multi_geo_event, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(analysis_year)

multi_geo_summary <- cdfi_tlr_harmonized |>
  summarise(
    total_rows = n(),
    total_events = n_distinct(event_key),
    multi_geo_rows = sum(is_multi_geo_event, na.rm = TRUE),
    multi_geo_events = n_distinct(event_key[is_multi_geo_event]),
    rows_from_report_year_fallback = sum(
      analysis_year_source == "report_year_fallback",
      na.rm = TRUE
    )
  )

# The sidecar .txt is intended to be human-readable reproducibility metadata.
# It should explain the raw inputs, the field mappings, and the judgment calls
# without requiring a future reader to reverse-engineer the script line by line.
harmonization_note_lines <- c(
  "CDFI TLR harmonization notes",
  paste0("Created: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "First-pass scope",
  "- Included: staged older CDFI TLR lending releases covering the historical 2003-2015 extract and annual 2018-2022 releases.",
  "- Excluded: the staged 2023 NMTC workbook in 0_inputs/2024_CDFI_NMTC_Release by explicit user instruction.",
  "",
  "Raw files read",
  paste0("- ", basename(paths$historical_tlr)),
  paste0("- ", basename(c(paths$annual_2018, paths$annual_2019, paths$annual_2020, paths$annual_2021, paths$annual_2022))),
  "",
  "Schema harmonization rules",
  "- Historical TLR fields used: org_id, trans_id, originalamount, projectfipscode_2000, projectfipscode_2010, investeetype, dateclosed, purpose, transactiontype, naicscode.",
  "- Annual 2018-2021 TLR fields used: org_id, trans_id, fiscalyear, originalamount, projectfipscode_2010, investeetype, dateclosed, purpose, transactiontype, naicscode.",
  "- Annual 2022 TLR fields used: org_id, trans_id, tlr_submission_year__c, original_loan_investment_amount_, fipscode_2010, investee_type__c, date_originated__c, purpose__c, transaction_type__c, naics_name.",
  "- Canonical amount field: original_amount.",
  "- Canonical investee-type field: investee_type, converted to uppercase.",
  "- Canonical industry field: industry_raw, populated from naicscode in older files and naics_name in the 2022 release.",
  "",
  "Year construction rules",
  "- report_year comes from fiscalyear in 2018-2021 and tlr_submission_year__c in 2022.",
  "- Historical TLR files do not expose a clean fiscalyear header field, so transaction_date is parsed from dateclosed and transaction_year is derived from that date.",
  "- analysis_year = transaction_year when transaction_date is observed; otherwise analysis_year = report_year.",
  "- Rows with analysis_year outside 2003-2022 were excluded from the first-pass comparable series.",
  paste0(
    "- Historical ILR fiscalyear audit confirmed explicit values from ",
    min(historical_ilr_years), " through ", max(historical_ilr_years), "."
  ),
  "",
  "Geography rules",
  "- projectfips fields were normalized by removing non-digits and treating blank / NONE / NULL style values as missing.",
  "- 10-digit tract-like geography values were left-padded to 11 digits to restore dropped leading zeros before deriving state and county FIPS.",
  "- Preferred geography field = project_fips_2010 when available, otherwise project_fips_2000.",
  "- state_fips = first 2 digits of the preferred geography when at least 2 digits are available.",
  "- county_fips = first 5 digits of the preferred geography when at least 5 digits are available.",
  "",
  "Transaction-event rules",
  "- event_key = report_year + org_id + trans_id when report_year is available; otherwise event_key = analysis_year + org_id + trans_id.",
  "- org_id + trans_id alone was not treated as a stable cross-file transaction key because those pairs are reused across report years.",
  "- Some event_keys appear on multiple geography rows within a year. Those rows were retained, and equal-split allocation weights were added for state and county geography aggregation.",
  "",
  "Business-sample rule",
  "- is_business = TRUE when investee_type == BUS.",
  "- The cleaned file retains all rows plus the business flag so downstream work can subset reproducibly.",
  "",
  "Exclusion summary",
  paste0("- Total raw rows inspected: ", format(excluded_summary$total_rows, big.mark = ",")),
  paste0("- Rows missing analysis_year: ", format(excluded_summary$rows_missing_analysis_year, big.mark = ",")),
  paste0("- Rows with analysis_year before 2003: ", format(excluded_summary$rows_before_2003, big.mark = ",")),
  paste0("- Rows with analysis_year after 2022: ", format(excluded_summary$rows_after_2022, big.mark = ",")),
  paste0(
    "- Historical rows excluded for pre-2003 transaction dates: ",
    format(excluded_summary$historical_rows_before_2003, big.mark = ",")
  ),
  "",
  "Post-filter summary",
  paste0("- Harmonized rows written: ", format(nrow(cdfi_tlr_harmonized), big.mark = ",")),
  paste0("- Distinct event_keys written: ", format(n_distinct(cdfi_tlr_harmonized$event_key), big.mark = ",")),
  paste0("- Multi-geo event_keys: ", format(multi_geo_summary$multi_geo_events, big.mark = ",")),
  paste0(
    "- Rows using report-year fallback for analysis_year: ",
    format(multi_geo_summary$rows_from_report_year_fallback, big.mark = ",")
  )
)

rds_out <- resolve_output_path("cdfi_tlr_harmonized.rds")
csv_out <- resolve_output_path("cdfi_field_coverage_by_year.csv")
txt_out <- resolve_output_path("cdfi_tlr_harmonization_notes.txt")

# The three outputs have different jobs:
# - RDS: downstream analysis backbone
# - CSV: quick year-by-year coverage audit
# - TXT: prose reproducibility note for humans
saveRDS(cdfi_tlr_harmonized, rds_out)
readr::write_csv(cdfi_field_coverage_by_year, csv_out)
writeLines(harmonization_note_lines, txt_out)

message("Wrote harmonized CDFI TLR output -> ", rds_out)
message("Wrote coverage audit -> ", csv_out)
message("Wrote harmonization notes -> ", txt_out)
