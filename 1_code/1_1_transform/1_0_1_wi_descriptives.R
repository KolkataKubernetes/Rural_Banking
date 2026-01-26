#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  1_0_1_wi_descriptives.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Build intermediate data outputs for Wisconsin descriptives
#             to support isolated visualization scripts in 1_code/1_2_visualize.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
})

overwrite <- FALSE

paths <- list(
  pitchbook_count = file.path("0_inputs", "Pitchbook", "Pitchbook_dealcount.xlsx"),
  pitchbook_vol   = file.path("0_inputs", "Pitchbook", "Pitchbook_dealvol.xlsx"),
  participation   = file.path("0_inputs", "CORI", "fips_participation.csv"),
  bds_fa          = file.path("0_inputs", "bds2023_st_fa.csv"),
  rucc            = file.path("0_inputs", "Ruralurbancontinuumcodes2023.xlsx"),
  formd_dir       = file.path("2_processed_data", "formd_years")
)

output_dir <- "2_processed_data"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

stopifnot(
  file.exists(paths$pitchbook_count),
  file.exists(paths$pitchbook_vol),
  file.exists(paths$participation),
  file.exists(paths$bds_fa),
  file.exists(paths$rucc),
  dir.exists(paths$formd_dir)
)

write_rds_df <- function(df, name) {
  stopifnot(is.data.frame(df))
  out_path <- file.path(output_dir, paste0(name, ".rds"))
  if (!overwrite && file.exists(out_path)) {
    stop("Refusing to overwrite existing output: ", out_path)
  }
  saveRDS(df, out_path)
}

# -----------------------------
# 1) Load inputs
# -----------------------------

dealcount <- readxl::read_xlsx(paths$pitchbook_count)
dealvol   <- readxl::read_xlsx(paths$pitchbook_vol)
participationdir <- readr::read_csv(paths$participation, show_col_types = FALSE)
bds_fa <- readr::read_csv(paths$bds_fa, show_col_types = FALSE)
rucc <- readxl::read_excel(paths$rucc)

formd_files <- list.files(paths$formd_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(formd_files) == 0) {
  stop("No Form D CSVs found in ", paths$formd_dir)
}

formd_data <- formd_files |>
  purrr::map_dfr(readr::read_csv, show_col_types = FALSE) |>
  select(-1) |>
  distinct()

# -----------------------------
# 2) Pitchbook: wide to long + derived series
# -----------------------------

count_wide <- dealcount |>
  pivot_longer(-State, names_to = "year", values_to = "count")

vol_wide <- dealvol |>
  pivot_longer(-State, names_to = "year", values_to = "count")

dealsize_wide <- inner_join(
  count_wide,
  vol_wide |> reframe(State, year, vol = count),
  by = c("State", "year")
) |>
  transmute(State, year, dealsize = vol / count)

count_iqr <- count_wide |>
  group_by(year) |>
  summarise(
    p25 = quantile(count, 0.25, na.rm = TRUE),
    p50 = quantile(count, 0.50, na.rm = TRUE),
    p75 = quantile(count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

vol_iqr <- vol_wide |>
  group_by(year) |>
  summarise(
    p25 = quantile(count, 0.25, na.rm = TRUE),
    p50 = quantile(count, 0.50, na.rm = TRUE),
    p75 = quantile(count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

size_iqr <- dealsize_wide |>
  group_by(year) |>
  summarise(
    p25 = quantile(dealsize, 0.25, na.rm = TRUE),
    p50 = quantile(dealsize, 0.50, na.rm = TRUE),
    p75 = quantile(dealsize, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

count_ts_data <- count_iqr |>
  left_join(
    count_wide |>
      group_by(year) |>
      summarise(dealcount_national = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    count_wide |>
      filter(!(State %in% c("California", "Massachusetts", "New York"))) |>
      group_by(year) |>
      summarise(dealcount_national_nonoutlier = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    count_wide |>
      filter(State %in% c("Minnesota", "Iowa", "Illinois", "Michigan", "Indiana")) |>
      group_by(year) |>
      summarise(dealcount_midwest = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    count_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealcount_wi = count),
    by = "year"
  ) |>
  mutate(
    year           = as.numeric(year),
    nonoutlier_pct = dealcount_national_nonoutlier / dealcount_national,
    midwest_pct    = dealcount_midwest / dealcount_national,
    wi_pct         = dealcount_wi / dealcount_national
  )

vol_ts_data <- vol_iqr |>
  left_join(
    vol_wide |>
      group_by(year) |>
      summarise(dealvol_national = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(!(State %in% c("California", "Massachusetts", "New York"))) |>
      group_by(year) |>
      summarise(dealvol_national_nonoutlier = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(State %in% c("Minnesota", "Iowa", "Illinois", "Michigan", "Indiana")) |>
      group_by(year) |>
      summarise(dealvol_midwest = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealvol_wi = count),
    by = "year"
  ) |>
  mutate(
    year = as.numeric(year),
    nonoutlier_pct = dealvol_national_nonoutlier / dealvol_national,
    wi_pct = dealvol_wi / dealvol_national,
    midwest_pct = dealvol_midwest / dealvol_national
  )

dealsize_ts_data <- size_iqr |>
  left_join(
    dealsize_wide |>
      group_by(year) |>
      summarise(dealsize_national = mean(dealsize, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    dealsize_wide |>
      filter(!(State %in% c("California", "Massachusetts", "New York"))) |>
      group_by(year) |>
      summarise(dealsize_national_nonoutlier = mean(dealsize, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    dealsize_wide |>
      filter(State %in% c("Minnesota", "Iowa", "Illinois", "Michigan", "Indiana")) |>
      group_by(year) |>
      summarise(dealsize_midwest = mean(dealsize, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    dealsize_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealsize_wi = dealsize),
    by = "year"
  ) |>
  mutate(
    year = as.numeric(year),
    nonoutlier_pct = dealsize_national_nonoutlier / dealsize_national,
    wi_pct = dealsize_wi / dealsize_national,
    midwest_pct = dealsize_midwest / dealsize_national
  )

vol_2024 <- vol_wide |>
  filter(year %in% c("2024")) |>
  filter(!(State %in% c("California", "Massachusetts", "New York"))) |>
  pivot_wider(names_from = year, values_from = count) |>
  rename(total = "2024")

dealsize_2024 <- dealsize_wide |>
  filter(year %in% c("2024")) |>
  pivot_wider(names_from = year, values_from = dealsize) |>
  rename(total = "2024")

# -----------------------------
# 3) BDS: age-0 firms
# -----------------------------

midwest_excl_wi <- c("27", "19", "17", "26", "18")
big3            <- c("06", "25", "36")
wi_fips         <- "55"

base <- bds_fa |>
  filter(year > 2014, fage == "a) 0") |>
  transmute(year, st, firms = as.numeric(firms))

grp_nat <- base |>
  group_by(year) |>
  summarise(firmcount = mean(firms, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

grp_nat_excl_big3 <- base |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(firmcount = mean(firms, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

grp_midwest <- base |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(firmcount = mean(firms, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

grp_wi <- base |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(firmcount = mean(firms, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

grp_all <- bind_rows(grp_nat, grp_nat_excl_big3, grp_midwest, grp_wi) |>
  left_join(
    grp_nat |> select(nat_avg = firmcount, year),
    by = "year"
  ) |>
  mutate(pct_of_nat = firmcount / nat_avg)

base_lf <- bds_fa |>
  filter(year > 2014, fage == "a) 0") |>
  left_join(participationdir, by = c("year", "st" = "FIPS")) |>
  transmute(
    year,
    st,
    firms_norm = as.numeric(firms) / (Force / 100000)
  )

grp_nat_lf <- base_lf |>
  group_by(year) |>
  summarise(firmcount = mean(firms_norm, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

grp_nat_excl_big3_lf <- base_lf |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(firmcount = mean(firms_norm, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

grp_midwest_lf <- base_lf |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(firmcount = mean(firms_norm, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

grp_wi_lf <- base_lf |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(firmcount = mean(firms_norm, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

grp_all_lf <- bind_rows(grp_nat_lf, grp_nat_excl_big3_lf, grp_midwest_lf, grp_wi_lf) |>
  left_join(
    grp_nat_lf |> select(year, nat_avg = firmcount),
    by = "year"
  ) |>
  mutate(pct_of_nat = firmcount / nat_avg)

# -----------------------------
# 4) Form D: filters and aggregations
# -----------------------------

formd_data_US <- formd_data |>
  filter(zip_class %in% c("US_ZIP + 4", "US_ZIP5")) |>
  filter(!(stateorcountrydescription %in% c(
    "ALBERTA, CANADA", "AMERICAN SAMOA", "ANGUILLA", "ANTIGUA AND BARBUDA",
    "ARGENTINA", "ARMENIA", "AUSTRALIA", "AUSTRIA", "AZERBAIJAN", "BAHAMAS",
    "BANGLADESH", "BARBADOS", "BELGIUM", "BELIZE", "BERMUDA", "BRAZIL",
    "BRITISH COLUMBIA, CANADA", "BULGARIA", "CANADA (FEDERAL LEVEL)",
    "CAYMAN ISLANDS", "CHILE", "CHINA", "COLOMBIA", "COOK ISLANDS",
    "COSTA RICA", "CROATIA", "DENMARK", "EGYPT", "ESTONIA", "ETHIOPIA",
    "FINLAND", "FRANCE", "GERMANY", "GHANA", "GIBRALTAR", "GREECE",
    "GRENADA", "GUAM", "GUATEMALA", "GUERNSEY", "HONDURAS", "HONG KONG",
    "INDONESIA", "IRELAND", "ISRAEL", "ITALY", "JAMAICA", "KENYA",
    "KOREA, REPUBLIC OF", "LUXEMBOURG", "MACAU", "MALAYSIA",
    "MARSHALL ISLANDS", "MAURITIUS", "MEXICO", "MICRONESIA, FEDERATED STATES OF",
    "MONACO", "MONGOLIA", "NETHERLANDS", "NETHERLANDS ANTILLES", "NIGERIA",
    "NEW ZEALAND", "NORTHERN MARIANA ISLANDS", "NORWAY", "ONTARIO, CANADA",
    "PAKISTAN", "PANAMA", "PERU", "PUERTO RICO", "QUEBEC, CANADA",
    "RUSSIAN FEDERATION", "RWANDA", "SAINT KITTS AND NEVIS", "SAINT LUCIA",
    "SAINT VINCENT AND THE GRENADINES", "SERBIA", "SEYCHELLES", "SINGAPORE",
    "SLOVAKIA", "SPAIN", "SWEDEN", "SWITZERLAND", "TAIWAN",
    "TAIWAN, PROVINCE OF CHINA", "THAILAND", "TURKEY", "UGANDA", "UKRAINE",
    "UNITED ARAB EMIRATES", "UNITED KINGDOM",
    "UNITED STATES MINOR OUTLYING ISLANDS", "URUGUAY", "VIET NAM",
    "VIRGIN ISLANDS, BRITISH", "VIRGIN ISLANDS, U.S.", ""
  ))) |>
  filter(accessionnumber != "0001584209-16-000007") |>
  filter(totalamountsold < 100000000) |>
  filter(!(stateorcountry %in% c("CA", "2Q", "MA", "NY", "PR", "X1", "I0"))) |>
  select(
    entityname, cik, biz_id, stateorcountry, stateorcountrydescription,
    zipcode, COUNTY, entitytype, year, over100recipientflag, incremental_amount
  ) |>
  filter(incremental_amount != 0)

formd_wi_county <- formd_data_US |>
  mutate(
    county_fips = stringr::str_pad(COUNTY, width = 5, side = "left", pad = "0")
  ) |>
  filter(substr(county_fips, 1, 2) == "55") |>
  group_by(county_fips) |>
  summarise(
    total_increment = sum(incremental_amount, na.rm = TRUE),
    n_filings       = n(),
    .groups         = "drop"
  )

formd_group_year <- formd_data_US |>
  mutate(
    county_fips = stringr::str_pad(COUNTY, width = 5, pad = "0"),
    st          = substr(county_fips, 1, 2)
  ) |>
  left_join(
    rucc |> mutate(RUCC_2023 = as.integer(RUCC_2023)) |> select(FIPS, RUCC_2023),
    by = c("county_fips" = "FIPS")
  ) |>
  select(year, st, incremental_amount, RUCC_2023) |>
  mutate(
    rucc_grp = case_when(
      RUCC_2023 %in% c(1, 2, 3, 4, 6, 8) ~ "metro/metro-adjacent",
      TRUE                               ~ "rural"
    )
  ) |>
  group_by(year, st, rucc_grp) |>
  summarise(
    incremental_dollars = sum(incremental_amount, na.rm = TRUE),
    dealcount           = n(),
    avg_dealsize        = incremental_dollars / dealcount,
    .groups = "drop"
  ) |>
  left_join(participationdir, by = c("year", "st" = "FIPS")) |>
  filter(!is.na(Force), Force > 0) |>
  mutate(
    adjusted_dollars = incremental_dollars / (Force / 100000)
  )

rucc_levels <- c("metro/metro-adjacent", "rural")

formd_base <- formd_group_year |>
  mutate(
    st       = stringr::str_pad(st, width = 2, pad = "0"),
    rucc_grp = factor(rucc_grp, levels = rucc_levels)
  ) |>
  select(year, st, rucc_grp, incremental_dollars, dealcount, adjusted_dollars)

formd_complete <- formd_base |>
  complete(
    year,
    st,
    rucc_grp = rucc_levels,
    fill = list(
      incremental_dollars = 0,
      dealcount           = 0,
      adjusted_dollars    = 0
    )
  )

series_levels <- c(
  "National avg.",
  "National avg. (excl. CA, MA, NY)",
  "Midwest avg. (excl. WI)",
  "Wisconsin"
)

vol_nat <- formd_complete |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

vol_nat_excl <- formd_complete |>
  filter(!st %in% big3) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

vol_midwest <- formd_complete |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

vol_wi <- formd_complete |>
  filter(st == wi_fips) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

vol_all <- bind_rows(vol_nat, vol_nat_excl, vol_midwest, vol_wi) |>
  mutate(series = factor(group, levels = series_levels))

vol_totals <- vol_all |>
  group_by(year, series) |>
  summarise(region_total = sum(value, na.rm = TRUE), .groups = "drop")

nat_totals <- vol_totals |>
  filter(series == "National avg.") |>
  rename(nat_total = region_total) |>
  select(year, nat_total)

vol_all <- vol_all |>
  left_join(vol_totals, by = c("year", "series")) |>
  left_join(nat_totals, by = "year") |>
  mutate(pct_of_nat = region_total / nat_total)

years <- sort(unique(vol_all$year))
year_index <- setNames(seq_along(years), years)

vol_all <- vol_all |>
  mutate(
    year_idx   = year_index[as.character(year)],
    series_idx = as.numeric(series),
    x_pos      = year_idx + (series_idx - 2.5) * 0.18
  )

adj_nat <- formd_complete |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

adj_nat_excl <- formd_complete |>
  filter(!st %in% big3) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

adj_midwest <- formd_complete |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

adj_wi <- formd_complete |>
  filter(st == wi_fips) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

adj_all <- bind_rows(adj_nat, adj_nat_excl, adj_midwest, adj_wi) |>
  mutate(series = factor(group, levels = series_levels))

adj_totals <- adj_all |>
  group_by(year, series) |>
  summarise(region_total = sum(value, na.rm = TRUE), .groups = "drop")

adj_nat_totals <- adj_totals |>
  filter(series == "National avg.") |>
  rename(nat_total = region_total) |>
  select(year, nat_total)

adj_all <- adj_all |>
  left_join(adj_totals, by = c("year", "series")) |>
  left_join(adj_nat_totals, by = "year") |>
  mutate(pct_of_nat = region_total / nat_total)

adj_years <- sort(unique(adj_all$year))
adj_year_index <- setNames(seq_along(adj_years), adj_years)

adj_all <- adj_all |>
  mutate(
    year_idx   = adj_year_index[as.character(year)],
    series_idx = as.numeric(series),
    x_pos      = year_idx + (series_idx - 2.5) * 0.18
  )

cnt_nat <- formd_complete |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

cnt_nat_excl <- formd_complete |>
  filter(!st %in% big3) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

cnt_midwest <- formd_complete |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

cnt_wi <- formd_complete |>
  filter(st == wi_fips) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

cnt_all <- bind_rows(cnt_nat, cnt_nat_excl, cnt_midwest, cnt_wi) |>
  mutate(series = factor(group, levels = series_levels))

cnt_totals <- cnt_all |>
  group_by(year, series) |>
  summarise(region_total = sum(value, na.rm = TRUE), .groups = "drop")

cnt_nat_totals <- cnt_totals |>
  filter(series == "National avg.") |>
  rename(nat_total = region_total) |>
  select(year, nat_total)

cnt_all <- cnt_all |>
  left_join(cnt_totals, by = c("year", "series")) |>
  left_join(cnt_nat_totals, by = "year") |>
  mutate(pct_of_nat = region_total / nat_total)

cnt_years <- sort(unique(cnt_all$year))
cnt_year_index <- setNames(seq_along(cnt_years), cnt_years)

cnt_all <- cnt_all |>
  mutate(
    year_idx   = cnt_year_index[as.character(year)],
    series_idx = as.numeric(series),
    x_pos      = year_idx + (series_idx - 2.5) * 0.18
  )

# ---- Figure 13/14: metro/rural deal size ----

metro_base <- formd_complete |>
  filter(rucc_grp == "metro/metro-adjacent") |>
  group_by(year, st) |>
  summarise(
    incremental_dollars = sum(incremental_dollars, na.rm = TRUE),
    dealcount           = sum(dealcount, na.rm = TRUE),
    .groups             = "drop"
  ) |>
  mutate(
    dealsize = ifelse(dealcount > 0, incremental_dollars / dealcount, NA_real_)
  )

metro_nat <- metro_base |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "National avg.")

metro_nat_excl <- metro_base |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "National avg. (excl. CA, MA, NY)")

metro_midwest <- metro_base |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "Midwest avg. (excl. WI)")

metro_wi <- metro_base |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "Wisconsin")

metro_all <- bind_rows(metro_nat, metro_nat_excl, metro_midwest, metro_wi) |>
  mutate(
    series = factor(series, levels = series_levels)
  )

metro_nat_ref <- metro_all |>
  filter(series == "National avg.") |>
  select(year, nat_value = value)

metro_all <- metro_all |>
  left_join(metro_nat_ref, by = "year") |>
  mutate(pct_of_nat = value / nat_value)

rural_base <- formd_complete |>
  filter(rucc_grp == "rural") |>
  group_by(year, st) |>
  summarise(
    incremental_dollars = sum(incremental_dollars, na.rm = TRUE),
    dealcount           = sum(dealcount, na.rm = TRUE),
    .groups             = "drop"
  ) |>
  mutate(
    dealsize = ifelse(dealcount > 0, incremental_dollars / dealcount, NA_real_)
  )

rural_nat <- rural_base |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "National avg.")

rural_nat_excl <- rural_base |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "National avg. (excl. CA, MA, NY)")

rural_midwest <- rural_base |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "Midwest avg. (excl. WI)")

rural_wi <- rural_base |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(value = mean(dealsize, na.rm = TRUE), .groups = "drop") |>
  mutate(series = "Wisconsin")

rural_all <- bind_rows(rural_nat, rural_nat_excl, rural_midwest, rural_wi) |>
  mutate(
    series = factor(series, levels = series_levels)
  )

rural_nat_ref <- rural_all |>
  filter(series == "National avg.") |>
  select(year, nat_value = value)

rural_all <- rural_all |>
  left_join(rural_nat_ref, by = "year") |>
  mutate(pct_of_nat = value / nat_value)

# ---- Figure 15/16/17: yearly averages ----

formd_yearly_averages <- formd_data_US |>
  select(year, stateorcountry, COUNTY, incremental_amount) |>
  left_join(rucc |> select(FIPS, RUCC_2023), by = c("COUNTY" = "FIPS")) |>
  mutate(
    rucc_type = ifelse(as.character(RUCC_2023) %in% c("1", "2", "3"), "metro", "rural")
  ) |>
  group_by(year, stateorcountry, rucc_type) |>
  summarise(total = sum(incremental_amount, na.rm = TRUE), .groups = "drop") |>
  group_by(stateorcountry, rucc_type) |>
  summarise(average_filings = mean(total, na.rm = TRUE), .groups = "drop") |>
  mutate(
    grp = case_when(
      stateorcountry %in% c("TX", "IL", "FL") ~ "Top 3 (TX, IL, FL)",
      stateorcountry == "WI" ~ "WI",
      TRUE ~ "All other states"
    )
  ) |>
  group_by(grp, rucc_type) |>
  summarise(mean_amount = mean(average_filings, na.rm = TRUE), .groups = "drop")

formd_yearly_avg_filing <- formd_data_US |>
  select(year, stateorcountry, COUNTY, incremental_amount) |>
  mutate(COUNTY = stringr::str_pad(COUNTY, 5, pad = "0")) |>
  left_join(rucc |> select(FIPS, RUCC_2023), by = c("COUNTY" = "FIPS")) |>
  mutate(
    rucc_type = ifelse(as.character(RUCC_2023) %in% c("1", "2", "3"), "metro", "rural")
  ) |>
  group_by(year, rucc_type) |>
  summarise(average_filings = mean(incremental_amount, na.rm = TRUE), .groups = "drop")

formd_yearly_avg_raised_biz <- formd_data_US |>
  select(year, stateorcountry, biz_id, COUNTY, incremental_amount) |>
  mutate(COUNTY = stringr::str_pad(COUNTY, 5, pad = "0")) |>
  left_join(rucc |> select(FIPS, RUCC_2023), by = c("COUNTY" = "FIPS")) |>
  mutate(
    rucc_type = ifelse(as.character(RUCC_2023) %in% c("1", "2", "3"), "metro", "rural")
  ) |>
  group_by(year, biz_id, rucc_type) |>
  summarise(raised = sum(incremental_amount, na.rm = TRUE), .groups = "drop") |>
  group_by(year, rucc_type) |>
  summarise(average_raised = mean(raised, na.rm = TRUE), .groups = "drop")

# -----------------------------
# 5) Write intermediate outputs
# -----------------------------

write_rds_df(count_ts_data, "count_ts_data")
write_rds_df(vol_ts_data, "vol_ts_data")
write_rds_df(dealsize_ts_data, "dealsize_ts_data")
write_rds_df(vol_2024, "vol_2024")
write_rds_df(dealsize_2024, "dealsize_2024")
write_rds_df(grp_all, "grp_all")
write_rds_df(grp_all_lf, "grp_all_lf")
write_rds_df(formd_data_US, "formd_data_US")
write_rds_df(formd_wi_county, "formd_wi_county")
write_rds_df(formd_complete, "formd_complete")
write_rds_df(vol_all, "vol_all")
write_rds_df(adj_all, "adj_all")
write_rds_df(cnt_all, "cnt_all")
write_rds_df(metro_all, "metro_all")
write_rds_df(rural_all, "rural_all")
write_rds_df(formd_yearly_averages, "formd_yearly_averages")
write_rds_df(formd_yearly_avg_filing, "formd_yearly_avg_filing")
write_rds_df(formd_yearly_avg_raised_biz, "formd_yearly_avg_raised_biz")
