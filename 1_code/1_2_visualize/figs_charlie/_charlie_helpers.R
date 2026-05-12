#///////////////////////////////////////////////////////////////////////////////
#----                Charlie Figure Translation Shared Helpers             ----
# File name:  _charlie_helpers.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Provide shared local-data helpers for Charlie figure
#             translations. This file is intentionally explicit so the
#             downstream figure scripts remain readable and auditable.
#///////////////////////////////////////////////////////////////////////////////

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(sf)
  library(scales)
})

charlie_bank_output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/bank_figs"
charlie_cu_output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_05_15/credit_union_figs"

charlie_fdic_dir <- file.path("0_inputs", "data_charlie", "FDIC")
charlie_cra_dir <- file.path("0_inputs", "data_charlie", "CRA")
charlie_ncua_dir <- file.path("0_inputs", "data_charlie", "NCUA")
charlie_county_shp <- file.path(
  "0_inputs", "WI_CensusTL_Counties_2019", "WI_CensusTL_Counties_2019.shp"
)

charlie_theme <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      axis.title = element_text(face = "bold"),
      plot.title = element_text(face = "bold"),
      legend.title = element_text(face = "bold"),
      axis.text.x = element_text(color = "black"),
      axis.text.y = element_text(color = "black")
    )
}

charlie_map_theme <- function(base_size = 11) {
  theme_void(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = element_text(face = "bold"),
      legend.title = element_text(face = "bold")
    )
}

save_charlie_fig <- function(plot_obj, filename, width, height, dpi = 300) {
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  ggsave(
    filename = filename,
    plot = plot_obj,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
  message("Saved -> ", filename)
}

clean_county_name <- function(x) {
  x |>
    stringr::str_replace("^\\.", "") |>
    stringr::str_replace(" County, Wisconsin$", "") |>
    stringr::str_replace(" County$", "") |>
    stringr::str_trim()
}

load_wi_counties <- function() {
  sf::read_sf(charlie_county_shp, quiet = TRUE) |>
    mutate(
      county = clean_county_name(NAME),
      county_upper = stringr::str_to_upper(county),
      county_fips = paste0(STATEFP, COUNTYFP)
    )
}

load_county_population_audit <- function(year) {
  if (year >= 2000 && year <= 2009) {
    path <- file.path(
      "0_inputs", "data_charlie", "co-est00int-01-55_audit_long.csv"
    )
  } else if (year >= 2020 && year <= 2024) {
    path <- file.path(
      "0_inputs", "data_charlie", "co-est2024-pop-55_audit_long.csv"
    )
  } else {
    stop("No reviewed county population audit artifact is available for year ", year)
  }

  readr::read_csv(path, show_col_types = FALSE) |>
    filter(year == !!year) |>
    mutate(
      county_upper = stringr::str_to_upper(county)
    )
}

load_fdic_sod <- function(year) {
  path <- file.path(
    charlie_fdic_dir,
    sprintf("SOD_CustomDownload_ALL_%d_06_30.csv", year)
  )

  out <- readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "latin1"),
    guess_max = 50000
  )

  names(out)[1] <- names(out)[1] |>
    stringr::str_replace("^ï»¿", "") |>
    stringr::str_replace("^\\ufeff", "") |>
    stringr::str_replace_all('"', "")

  out
}

fdic_available_years <- function() {
  list.files(
    charlie_fdic_dir,
    pattern = "^SOD_CustomDownload_ALL_[0-9]{4}_06_30\\.csv$"
  ) |>
    stringr::str_extract("[0-9]{4}") |>
    as.integer() |>
    sort()
}

trim_bank_name <- function(x) {
  x |>
    stringr::str_replace(", National Association", "") |>
    stringr::str_replace(", N\\.A\\.", "") |>
    stringr::str_replace(", f\\.s\\.b\\.", "") |>
    stringr::str_trim()
}

ncua_branch_dir_for_year <- function(year) {
  if (year >= 2015) {
    file.path(charlie_ncua_dir, sprintf("call-report-data-%d-12", year))
  } else {
    file.path(charlie_ncua_dir, sprintf("QCR%d12", year))
  }
}

ncua_branch_file_for_year <- function(year) {
  file.path(ncua_branch_dir_for_year(year), "Credit Union Branch Information.txt")
}

ncua_fs_file_for_year <- function(year) {
  file.path(ncua_branch_dir_for_year(year), "FS220L.txt")
}

load_ncua_branch <- function(year) {
  path <- ncua_branch_file_for_year(year)
  if (!file.exists(path)) {
    stop("Missing NCUA branch file for year ", year, ": ", path)
  }

  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "cp1252"),
    guess_max = 50000
  )
}

load_ncua_fs <- function(year) {
  path <- ncua_fs_file_for_year(year)
  if (!file.exists(path)) {
    stop("Missing NCUA financial-statement file for year ", year, ": ", path)
  }

  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "cp1252"),
    guess_max = 50000
  )
}

wi_cu_main_offices <- function(year) {
  load_ncua_branch(year) |>
    filter(
      PhysicalAddressStateCode == "WI",
      MainOffice == "Yes"
    ) |>
    distinct(CU_NUMBER)
}

ncua_total_assets_column <- function(df) {
  if ("ACCT_010" %in% names(df)) {
    return("ACCT_010")
  }

  if ("ACCT_025B1" %in% names(df)) {
    return("ACCT_025B1")
  }

  stop("No staged total-assets field was found in the NCUA financial file.")
}

cra_fixed_widths <- c(
  5, 4, 1, 1, 2, 3, 5, 7, 1, 1, 3, 3, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 29
)

cra_fixed_names <- c(
  "Table_ID", "Year", "Loan_Type", "Action_Type", "State_FIPS", "County_FIPS",
  "MSA_MD", "Census_Tract", "Split_County", "Pop_Class", "Income_Group",
  "Report_Level", "Loans_U100k_Num", "Loans_U100k_Amt",
  "Loans_100_250_Num", "Loans_100_250_Amt",
  "Loans_250_1M_Num", "Loans_250_1M_Amt",
  "Loans_Over1M_Num", "Loans_Over1M_Amt",
  "Loans_Rev_Num", "Loans_Rev_Amt", "Filler"
)

load_cra_wi_frequency_series <- function() {
  records <- vector("list", length = 0)

  for (yr in 2000:2004) {
    df <- readr::read_delim(
      file.path(charlie_cra_dir, "aggr", sprintf("tract_%d.txt", yr)),
      delim = "|",
      show_col_types = FALSE,
      progress = FALSE
    )

    wi <- df |>
      filter(state == 55, report_level == 200)

    # Charlie's Python script looks for num_1M, but the staged 2000-2004
    # CRA files store this bucket as num_1mil. We read the local column
    # explicitly so the translated R series includes all three size bands.
    records[[length(records) + 1]] <- tibble(
      year = yr,
      loans_u100k_num = sum(wi$num_100k, na.rm = TRUE),
      loans_100_250_num = sum(wi$`num_250k`, na.rm = TRUE),
      loans_250_1m_num = sum(wi$`num_1mil`, na.rm = TRUE)
    )
  }

  for (yr in 2005:2018) {
    df <- readr::read_csv(
      file.path(charlie_cra_dir, "cra_old", sprintf("cra_%d.csv", yr)),
      show_col_types = FALSE,
      progress = FALSE
    ) |>
      mutate(state_fips = stringr::str_sub(fips, 1, 2))

    wi <- df |>
      filter(state_fips == "55")

    records[[length(records) + 1]] <- tibble(
      year = yr,
      loans_u100k_num = sum(as.numeric(wi$loan_count_100k), na.rm = TRUE),
      loans_100_250_num = sum(as.numeric(wi$loan_count_250k), na.rm = TRUE),
      loans_250_1m_num = sum(as.numeric(wi$loan_count_1M), na.rm = TRUE)
    )
  }

  for (yr in 2019:2023) {
    df <- readr::read_fwf(
      file.path(charlie_cra_dir, sprintf("%dexp_aggr", yr - 2000),
                sprintf("cra%d_Aggr_A11.dat", yr)),
      col_positions = readr::fwf_widths(cra_fixed_widths, cra_fixed_names),
      show_col_types = FALSE,
      progress = FALSE
    )

    wi <- df |>
      filter(State_FIPS == "55", Report_Level == "200") |>
      mutate(
        across(
          c(Loans_U100k_Num, Loans_100_250_Num, Loans_250_1M_Num),
          ~ as.numeric(replace_na(.x, "0"))
        )
      )

    records[[length(records) + 1]] <- tibble(
      year = yr,
      loans_u100k_num = sum(wi$Loans_U100k_Num, na.rm = TRUE),
      loans_100_250_num = sum(wi$Loans_100_250_Num, na.rm = TRUE),
      loans_250_1m_num = sum(wi$Loans_250_1M_Num, na.rm = TRUE)
    )
  }

  bind_rows(records) |>
    arrange(year)
}

load_cra_wi_volume_series <- function() {
  records <- vector("list", length = 0)

  for (yr in 2000:2004) {
    df <- readr::read_delim(
      file.path(charlie_cra_dir, "aggr", sprintf("tract_%d.txt", yr)),
      delim = "|",
      show_col_types = FALSE,
      progress = FALSE
    )

    wi <- df |>
      filter(state == 55, report_level == 200)

    # Charlie's Python script looks for vol_1M, but the staged 2000-2004
    # CRA files store this bucket as vol_1mil. We read the local column
    # explicitly so the translated R series includes all three size bands.
    records[[length(records) + 1]] <- tibble(
      year = yr,
      loans_u100k_amt = sum(wi$vol_100k, na.rm = TRUE) * 1000,
      loans_100_250_amt = sum(wi$vol_250k, na.rm = TRUE) * 1000,
      loans_250_1m_amt = sum(wi$vol_1mil, na.rm = TRUE) * 1000
    )
  }

  for (yr in 2005:2018) {
    df <- readr::read_csv(
      file.path(charlie_cra_dir, "cra_old", sprintf("cra_%d.csv", yr)),
      show_col_types = FALSE,
      progress = FALSE
    ) |>
      mutate(state_fips = stringr::str_sub(fips, 1, 2))

    wi <- df |>
      filter(state_fips == "55")

    records[[length(records) + 1]] <- tibble(
      year = yr,
      loans_u100k_amt = sum(as.numeric(wi$loan_vol_100k), na.rm = TRUE),
      loans_100_250_amt = sum(as.numeric(wi$loan_vol_250k), na.rm = TRUE),
      loans_250_1m_amt = sum(as.numeric(wi$loan_vol_1M), na.rm = TRUE)
    )
  }

  for (yr in 2019:2023) {
    df <- readr::read_fwf(
      file.path(charlie_cra_dir, sprintf("%dexp_aggr", yr - 2000),
                sprintf("cra%d_Aggr_A11.dat", yr)),
      col_positions = readr::fwf_widths(cra_fixed_widths, cra_fixed_names),
      show_col_types = FALSE,
      progress = FALSE
    )

    wi <- df |>
      filter(State_FIPS == "55", Report_Level == "200") |>
      mutate(
        across(
          c(Loans_U100k_Amt, Loans_100_250_Amt, Loans_250_1M_Amt),
          ~ as.numeric(replace_na(.x, "0")) * 1000
        )
      )

    records[[length(records) + 1]] <- tibble(
      year = yr,
      loans_u100k_amt = sum(wi$Loans_U100k_Amt, na.rm = TRUE),
      loans_100_250_amt = sum(wi$Loans_100_250_Amt, na.rm = TRUE),
      loans_250_1m_amt = sum(wi$Loans_250_1M_Amt, na.rm = TRUE)
    )
  }

  bind_rows(records) |>
    arrange(year)
}

load_cra_2023_county_aggregates <- function() {
  readr::read_fwf(
    file.path(charlie_cra_dir, "23exp_aggr", "cra2023_Aggr_A11.dat"),
    col_positions = readr::fwf_widths(cra_fixed_widths, cra_fixed_names),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    filter(State_FIPS == "55", Report_Level == "200") |>
    mutate(
      County_FIPS = stringr::str_pad(County_FIPS, 3, pad = "0"),
      Loans_U100k_Num = as.numeric(replace_na(Loans_U100k_Num, "0")),
      Loans_U100k_Amt = as.numeric(replace_na(Loans_U100k_Amt, "0")) * 1000
    )
}

load_cra_2023_state_aggregates <- function() {
  readr::read_fwf(
    file.path(charlie_cra_dir, "23exp_aggr", "cra2023_Aggr_A11.dat"),
    col_positions = readr::fwf_widths(cra_fixed_widths, cra_fixed_names),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    filter(Report_Level == "200") |>
    mutate(
      Loans_U100k_Num = as.numeric(replace_na(Loans_U100k_Num, "0")),
      Loans_U100k_Amt = as.numeric(replace_na(Loans_U100k_Amt, "0")) * 1000
    )
}

load_wi_population_from_participation <- function(years = 2000:2023) {
  readr::read_csv(
    file.path("0_inputs", "CORI", "fips_participation.csv"),
    show_col_types = FALSE
  ) |>
    mutate(
      FIPS = stringr::str_pad(as.character(FIPS), 2, pad = "0"),
      Participation = readr::parse_number(as.character(Participation)),
      Force = readr::parse_number(as.character(Force)),
      year = as.integer(year)
    ) |>
    filter(FIPS == "55", year %in% years) |>
    transmute(
      year,
      population = Force / (Participation / 100)
    )
}

build_cra_under100k_average_size <- function() {
  load_cra_wi_frequency_series() |>
    select(year, loans_u100k_num) |>
    inner_join(
      load_cra_wi_volume_series() |>
        select(year, loans_u100k_amt),
      by = "year"
    ) |>
    mutate(
      avg_size = dplyr::if_else(
        loans_u100k_num > 0,
        loans_u100k_amt / loans_u100k_num,
        NA_real_
      )
    )
}
