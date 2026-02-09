#///////////////////////////////////////////////////////////////////////////////
#----     Ingest Utility: US Census CBP Metadata Scan            ----
# File name:  census_CBP_metadata_scan.R
# Author:     Codex
# Created:    2026-02-08
# Purpose:    Diagnose which NAICS/industry fields are available in CBP API
#             metadata by year without running the full CBP data pull.
#
# Default behavior:
# - Reads metadata only from /cbp/variables.json for each year in `years`.
# - Prints a year-level summary and candidate field list to console.
# - Does NOT write files unless `write_outputs <- TRUE`.
#
# Optional outputs when write_outputs <- TRUE:
# - 2_processed_data/cbp_metadata/cbp_variables_long.csv
# - 2_processed_data/cbp_metadata/cbp_variable_presence_wide.csv
# - 2_processed_data/cbp_metadata/cbp_year_summary.csv
#///////////////////////////////////////////////////////////////////////////////

suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
  library(dplyr)
  library(purrr)
  library(readr)
  library(tidyr)
  library(stringr)
})

# -----------------------------
# Logging helpers
# -----------------------------
log_line <- function(...) {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message("[", ts, "] ", paste0(..., collapse = ""))
  flush.console()
}

log_stage <- function(stage_name) {
  log_line("\n========== ", stage_name, " ==========")
}

# -----------------------------
# 0) Configuration
# -----------------------------
years <- 2010:2023
write_outputs <- FALSE
overwrite <- FALSE
out_dir <- file.path("2_processed_data", "cbp_metadata")
run_start <- Sys.time()

# -----------------------------
# 1) Metadata pull helper
# -----------------------------
cbp_list_vars_meta <- function(year) {
  url <- paste0("https://api.census.gov/data/", year, "/cbp/variables.json")

  resp <- request(url) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  if (resp_status(resp) != 200) {
    stop("Metadata request failed for year ", year, ": HTTP ", resp_status(resp))
  }

  j <- fromJSON(resp_body_string(resp))

  tibble(
    year = year,
    name = names(j$variables),
    label = map_chr(j$variables, "label", .default = NA_character_),
    concept = map_chr(j$variables, "concept", .default = NA_character_),
    predicate_type = map_chr(j$variables, "predicateType", .default = NA_character_),
    required = map_chr(j$variables, "required", .default = NA_character_)
  ) |>
    arrange(name)
}

# -----------------------------
# 2) Pull metadata for all years
# -----------------------------
log_stage("CBP Metadata Pull")
log_line("Pulling /variables.json for years ", min(years), "-", max(years))

n_years <- length(years)
year_idx <- 0L
vars_list <- vector("list", n_years)

for (y in years) {
  year_idx <- year_idx + 1L
  t0 <- Sys.time()
  log_line("[", year_idx, "/", n_years, "] Start year ", y)

  vars_y <- cbp_list_vars_meta(y)
  vars_list[[year_idx]] <- vars_y

  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  log_line(
    "[", year_idx, "/", n_years, "] Done year ", y,
    " | vars=", nrow(vars_y),
    " | elapsed=", sprintf("%.1fs", elapsed)
  )
}

vars_long <- bind_rows(vars_list)
log_line("Metadata pull complete. Total rows=", nrow(vars_long))

# -----------------------------
# 3) Flag NAICS/industry candidates
# -----------------------------
log_stage("Candidate Detection")
is_industry_candidate <- function(name, label, concept) {
  txt <- paste(name, label, concept, sep = " | ")
  str_detect(
    txt,
    regex("NAICS|industry|industries|sector|SIC", ignore_case = TRUE)
  )
}

vars_candidates <- vars_long |>
  mutate(
    industry_candidate = is_industry_candidate(name, label, concept),
    candidate_type = case_when(
      str_detect(name, "^NAICS") ~ "naics_named",
      str_detect(paste(label, concept), regex("NAICS", ignore_case = TRUE)) ~ "naics_labeled",
      str_detect(paste(label, concept), regex("industry|industries", ignore_case = TRUE)) ~ "industry_labeled",
      str_detect(paste(label, concept), regex("sector", ignore_case = TRUE)) ~ "sector_labeled",
      str_detect(paste(name, label, concept), regex("SIC", ignore_case = TRUE)) ~ "sic_related",
      TRUE ~ "other"
    )
  ) |>
  filter(industry_candidate)

# Preferred NAICS query var to test in data pulls (if needed later).
naics_preference <- c("NAICS2022", "NAICS2017", "NAICS2012", "NAICS2007", "NAICS")

year_summary <- vars_long |>
  group_by(year) |>
  summarise(
    n_total_vars = n(),
    .groups = "drop"
  ) |>
  left_join(
    vars_candidates |>
      group_by(year) |>
      summarise(
        n_industry_candidates = n(),
        n_naics_named = sum(str_detect(name, "^NAICS")),
        preferred_naics_var = {
          hits <- name[name %in% naics_preference]
          pref <- naics_preference[naics_preference %in% hits]
          ifelse(length(pref) > 0, pref[1], NA_character_)
        },
        .groups = "drop"
      ),
    by = "year"
  ) |>
  mutate(
    n_industry_candidates = coalesce(n_industry_candidates, 0L),
    n_naics_named = coalesce(n_naics_named, 0L)
  ) |>
  arrange(year)

presence_wide <- vars_candidates |>
  distinct(year, name) |>
  mutate(present = 1L) |>
  tidyr::pivot_wider(
    names_from = year,
    values_from = present,
    values_fill = 0L
  ) |>
  arrange(name)

log_line(
  "Candidate scan complete. Industry-like rows=", nrow(vars_candidates),
  " | unique candidate vars=", n_distinct(vars_candidates$name)
)

# -----------------------------
# 4) Console diagnostics
# -----------------------------
log_stage("Console Diagnostics")
log_line("Printing year summary (all rows)")
print(year_summary, n = Inf)

log_line("Printing candidate variable table (first 200 rows)")
print(
  vars_candidates |>
    select(year, name, candidate_type, label, concept) |>
    arrange(year, name),
  n = 200
)

# -----------------------------
# 5) Optional non-destructive file outputs
# -----------------------------
if (isTRUE(write_outputs)) {
  log_stage("Write Outputs")
  log_line("write_outputs=TRUE. Preparing optional CSV outputs in ", out_dir)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
    log_line("Created directory: ", out_dir)
  }

  out_long <- file.path(out_dir, "cbp_variables_long.csv")
  out_presence <- file.path(out_dir, "cbp_variable_presence_wide.csv")
  out_summary <- file.path(out_dir, "cbp_year_summary.csv")

  existing <- c(out_long, out_presence, out_summary)[
    file.exists(c(out_long, out_presence, out_summary))
  ]
  if (length(existing) > 0 && !isTRUE(overwrite)) {
    stop(
      "Refusing to overwrite existing output(s): ",
      paste(existing, collapse = ", "),
      ". Set overwrite <- TRUE to replace."
    )
  }

  write_csv(vars_long, out_long)
  log_line("Wrote: ", out_long)
  write_csv(presence_wide, out_presence)
  log_line("Wrote: ", out_presence)
  write_csv(year_summary, out_summary)
  log_line("Wrote: ", out_summary)

  log_line("Finished writing metadata diagnostics outputs.")
} else {
  log_stage("Write Outputs")
  log_line("write_outputs=FALSE. No files written.")
}

total_elapsed <- as.numeric(difftime(Sys.time(), run_start, units = "secs"))
log_stage("Run Complete")
log_line("Completed metadata scan in ", sprintf("%.1fs", total_elapsed))

invisible(
  list(
    vars_long = vars_long,
    vars_candidates = vars_candidates,
    presence_wide = presence_wide,
    year_summary = year_summary
  )
)
