#///////////////////////////////////////////////////////////////////////////////
#----                           CORI Form D Pull                            ----
# File name:  CORI_formd_new.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-20
# Purpose:    Pull SEC Form D data via dform, apply CORI cleaning/join logic,
#             and generate validation summaries aligned to upstream method.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

# If dform is not installed, install from the local upstream snapshot:
# remotes::install_local("0_inputs/upstream/dform")
# htmltab is required by dform for codebook parsing; install if missing.

suppressPackageStartupMessages({
  library(dform)
  library(httr)
  library(tidyverse)
  library(readxl)
  library(jsonlite)
})

# Identify yourself to SEC endpoints if needed
set_config(user_agent("UW-Madison AAE (imajumdar@wisc.edu)"))
options(HTTPUserAgent = "UW-Madison AAE (imajumdar@wisc.edu)")

config <- list(
  years = 2019:2023,
  quarters = 1:4,
  remove_duplicates = TRUE,
  use_cache = TRUE,
  output_dir = "1_processed_data"
)

paths <- list(
  zip_crosswalk = "0_inputs/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx",
  rurality_geojson = "0_inputs/upstream/formd-interactive-map/src/data/formd_map.json",
  labor_force = "0_inputs/CORI/fips_participation.csv"
)

if (!dir.exists(config$output_dir)) {
  dir.create(config$output_dir, recursive = TRUE)
}

# -----------------------------
# 1) Pull Form D data via dform
# -----------------------------

dfm <- dForm$new()

dfm$load_data(
  years = config$years,
  quarter = config$quarters,
  remove_duplicates = config$remove_duplicates,
  use_cache = config$use_cache
)

issuers <- dfm$issuers
offerings <- dfm$offerings

# -----------------------------
# 2) Load dependencies
# -----------------------------

zip_county_crosswalk <- readxl::read_excel(paths$zip_crosswalk)

# Rurality + population from formd_map.json
rurality_geo <- jsonlite::fromJSON(paths$rurality_geojson)

rurality_lookup <- as_tibble(rurality_geo$features$properties) |>
  transmute(
    county_fips = stringr::str_pad(as.character(geoid_co), width = 5, side = "left", pad = "0"),
    rurality = rurality,
    pop = as.numeric(pop)
  )

# Labor force participation (used for per 100k labor force if needed)
participation <- readr::read_csv(paths$labor_force, show_col_types = FALSE)

# -----------------------------
# 3) Clean issuer names and zips
# -----------------------------

issuers <- issuers |>
  mutate(
    entityname = stringr::str_replace_all(entityname, "[[:punct:]]", ""),
    city = stringr::str_replace_all(city, "[[:punct:]]", "")
  ) |>
  mutate(
    entityname = stringr::str_squish(entityname),
    city = stringr::str_squish(city)
  ) |>
  mutate(across(c(entityname, city), ~stringr::str_to_upper(.x)))

# -----------------------------
# 4) HUD ZIP to county crosswalk
# -----------------------------

zip_crosswalk_clean <- zip_county_crosswalk |>
  group_by(ZIP) |>
  filter(BUS_RATIO == max(BUS_RATIO, na.rm = TRUE)) |>
  filter(TOT_RATIO == max(TOT_RATIO, na.rm = TRUE)) |>
  ungroup()

issuers <- issuers |>
  mutate(
    zip_raw = zipcode,
    zip5 = stringr::str_extract(zipcode, "\\d{5}"),
    zip_class = dplyr::case_when(
      stringr::str_detect(zipcode, "^\\d{5}-\\d{4}$") ~ "US_ZIP + 4",
      stringr::str_detect(zipcode, "^\\d{5}$") ~ "US_ZIP5",
      stringr::str_detect(stringr::str_to_upper(zipcode), "^[A-Z]\\d[A-Z][ -]?\\d[A-Z]\\d$") ~ "CAN_postal",
      TRUE ~ "Other_or_foreign"
    )
  )

issuers_match <- issuers |>
  left_join(zip_crosswalk_clean, by = c("zip5" = "ZIP"))

# -----------------------------
# 5) Year of incorporation logic
# -----------------------------

issuers_match <- issuers_match |>
  group_by(cik, entityname) |>
  mutate(
    minyear_value = suppressWarnings(min(yearofinc_value_entered, na.rm = TRUE)),
    fallback = dplyr::first(na.omit(yearofinc_timespan_choice)),
    minyear = if_else(
      is.finite(minyear_value),
      as.character(minyear_value),
      fallback
    )
  ) |>
  ungroup() |>
  select(-minyear_value, -fallback)

# -----------------------------
# 6) Join issuers and offerings
# -----------------------------

issuers_match_primary <- issuers_match |>
  filter(is_primaryissuer_flag == "YES")

issuers_offerings <- left_join(
  issuers_match_primary,
  offerings,
  by = c("accessionnumber", "year", "quarter")
)

# Collapse industries into a comma-separated string if present
industry_cols <- intersect(
  names(issuers_offerings),
  c("industrygroup", "industrygroupdescription", "industrygroupname")
)

if (length(industry_cols) > 0) {
  industry_col <- industry_cols[[1]]
  issuers_offerings <- issuers_offerings |>
    group_by(cik, entityname) |>
    mutate(
      industry_collapsed = paste0(sort(unique(na.omit(.data[[industry_col]]))), collapse = ", ")
    ) |>
    ungroup()
}

# -----------------------------
# 7) Business ID and funding rounds
# -----------------------------

issuers_offerings <- issuers_offerings |>
  mutate(
    cik = as.character(cik),
    biz_id = paste0(as.character(cik), "_", substr(accessionnumber, 1, 10))
  )

issuers_offerings <- issuers_offerings %>%
  group_by(
    biz_id,
    sale_date,
    isequitytype,
    isdebttype,
    ispooledinvestmentfundtype,
    isbusinesscombinationtrans
  ) %>%
  mutate(.round_key = dplyr::cur_group_id()) %>%
  ungroup() %>%
  group_by(biz_id) %>%
  mutate(funding_round_id = dplyr::dense_rank(.round_key)) %>%
  ungroup() %>%
  select(-.round_key)

# -----------------------------
# 8) Incremental amount sold
# -----------------------------

issuers_offerings <- issuers_offerings %>%
  mutate(totalamountsold = as.numeric(totalamountsold))

issuers_offerings <- issuers_offerings %>%
  group_by(biz_id, funding_round_id) %>%
  arrange(accessionnumber, .by_group = TRUE) %>%
  mutate(
    incremental_amount = totalamountsold - lag(totalamountsold),
    incremental_amount = if_else(
      is.na(incremental_amount),
      totalamountsold,
      incremental_amount
    ),
    incremental_amount_clean = if_else(is.na(incremental_amount) | incremental_amount < 0, 0, incremental_amount)
  ) %>%
  ungroup()

# -----------------------------
# 9) County-level aggregation and rurality join
# -----------------------------

issuers_offerings <- issuers_offerings |>
  mutate(
    county_fips = stringr::str_pad(as.character(COUNTY), width = 5, side = "left", pad = "0")
  )

county_year <- issuers_offerings |>
  group_by(year, county_fips) |>
  summarise(
    total_incremental = sum(incremental_amount_clean, na.rm = TRUE),
    filings = n(),
    .groups = "drop"
  ) |>
  left_join(rurality_lookup, by = "county_fips") |>
  mutate(
    rurality_group = if_else(rurality == "Metro", "nonrural", "rural"),
    per_capita = if_else(!is.na(pop) & pop > 0, total_incremental / pop, NA_real_)
  )

# Yearly per-capita totals by rurality
rurality_year <- county_year |>
  group_by(year, rurality_group) |>
  summarise(
    total_incremental = sum(total_incremental, na.rm = TRUE),
    total_pop = sum(pop, na.rm = TRUE),
    per_capita = if_else(total_pop > 0, total_incremental / total_pop, NA_real_),
    .groups = "drop"
  )

# Figure 8 validation targets (5-year averages)
figure8_targets <- tibble::tribble(
  ~rurality_group, ~period, ~per_capita_target,
  "rural",    "2014-2018", 73,
  "rural",    "2019-2023", 112,
  "nonrural", "2014-2018", 729,
  "nonrural", "2019-2023", 802
)

figure8_validation <- rurality_year |>
  mutate(
    period = dplyr::case_when(
      year >= 2014 & year <= 2018 ~ "2014-2018",
      year >= 2019 & year <= 2023 ~ "2019-2023",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(period)) |>
  group_by(rurality_group, period) |>
  summarise(
    per_capita_avg = mean(per_capita, na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(figure8_targets, by = c("rurality_group", "period")) |>
  mutate(
    diff = per_capita_avg - per_capita_target,
    pct_diff = diff / per_capita_target
  )

# Figure 11 summary (no numeric targets yet; capture distribution by rurality)
figure11_summary <- issuers_offerings |>
  left_join(rurality_lookup, by = "county_fips") |>
  mutate(rurality_group = if_else(rurality == "Metro", "nonrural", "rural")) |>
  group_by(rurality_group) |>
  summarise(
    filings = n(),
    mean_incremental = mean(incremental_amount_clean, na.rm = TRUE),
    median_incremental = median(incremental_amount_clean, na.rm = TRUE),
    .groups = "drop"
  )

# -----------------------------
# 10) QC summary
# -----------------------------

qc_summary <- tibble(
  years = paste0(min(config$years), "-", max(config$years)),
  issuers_count = nrow(issuers),
  offerings_count = nrow(offerings),
  joined_count = nrow(issuers_offerings),
  unique_accession_count = dplyr::n_distinct(issuers_offerings$accessionnumber),
  negative_incremental_count = sum(issuers_offerings$incremental_amount < 0, na.rm = TRUE),
  unmatched_zip_count = sum(is.na(issuers_match$COUNTY))
)

# -----------------------------
# 11) Outputs
# -----------------------------

year_output_dir <- file.path(config$output_dir, "formd_years")
if (!dir.exists(year_output_dir)) {
  dir.create(year_output_dir, recursive = TRUE)
}

issuers_offerings |>
  filter(!is.na(year)) |>
  group_by(year) |>
  group_walk(~{
    year_val <- .y$year
    write_csv(.x, file.path(year_output_dir, paste0("formd_", year_val, ".csv")))
  })

write_csv(
  qc_summary,
  file.path(config$output_dir, "formd_qc_summary.csv")
)

write_csv(
  figure8_validation,
  file.path(config$output_dir, "formd_fig8_validation.csv")
)

write_csv(
  figure11_summary,
  file.path(config$output_dir, "formd_fig11_summary.csv")
)

message(
  "Form D pull complete. Outputs written to: ",
  config$output_dir,
  " (yearly files in ",
  year_output_dir,
  ")"
)
