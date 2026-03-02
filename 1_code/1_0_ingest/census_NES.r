#///////////////////////////////////////////////////////////////////////////////
#----     Ingest: US Census Nonemployer Statistics              ----
# File name:  census_NES.r
# Author:     Inder Majumdar
# Created:    2026-03-01
# Purpose:    Ingest US Census Nonemployer Statistics (NES) Data
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

## Packages

library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)

# ---- Census API key (optional) ----
load_census_key <- function(path = file.path("0_inputs", "census_apikey.md")) {
  if (!file.exists(path)) return(NA_character_)
  key <- readLines(path, warn = FALSE)
  key <- trimws(paste(key, collapse = ""))
  if (!nzchar(key)) return(NA_character_)
  key
}

# ---- Core fetch function ----
nes_get <- function(year,
                    vars = c("NAME", "NESTAB", "NRCPTOT"),
                    state = NULL,
                    county = "*",
                    naics = NULL,
                    naics_var = "NAICS2017",
                    key = Sys.getenv("CENSUS_API_KEY", unset = NA)) {

  base <- paste0("https://api.census.gov/data/", year, "/nonemp")

  if (is.null(state)) stop("Provide a 2-digit state FIPS code (e.g., '55' for WI).")

  query <- list(
    get = paste(vars, collapse = ","),
    `for` = paste0("county:", county),
    `in` = paste0("state:", state)
  )

  if (!is.null(naics)) query[[naics_var]] <- naics

  if (is.na(key) || !nzchar(key)) key <- load_census_key()
  if (!is.na(key) && nzchar(key)) query$key <- key

  resp <- request(base) |>
    req_url_query(!!!query) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  make_empty <- function(cols) {
    num_cols <- c("NESTAB", "EMP", "PAYANN", "PAYQTR1", "NRCPTOT", "RCPTOT")
    col_list <- lapply(cols, function(x) {
      if (x %in% num_cols) numeric() else character()
    })
    tibble::tibble(!!!setNames(col_list, cols))
  }

  if (resp_status(resp) == 204) {
    out_cols <- c(vars, "state", "county")
    return(make_empty(out_cols))
  }

  if (resp_status(resp) != 200) {
    raw_bytes <- tryCatch(resp_body_raw(resp), error = function(e) raw(0))
    body_txt <- if (length(raw_bytes) > 0) rawToChar(raw_bytes) else ""
    stop("Census API request failed: HTTP ", resp_status(resp), "\n", body_txt)
  }

  raw_bytes <- resp_body_raw(resp)
  if (length(raw_bytes) == 0) {
    out_cols <- c(vars, "state", "county")
    return(make_empty(out_cols))
  }

  raw <- rawToChar(raw_bytes)
  arr <- fromJSON(raw)

  out <- as_tibble(arr[-1, , drop = FALSE], .name_repair = "minimal")
  names(out) <- make.unique(arr[1, ])

  out <- out |>
    mutate(across(any_of(c("NESTAB", "EMP", "PAYANN", "PAYQTR1", "NRCPTOT", "RCPTOT")), readr::parse_number))

  out
}

nes_list_vars <- function(year) {
  url <- paste0("https://api.census.gov/data/", year, "/nonemp/variables.json")
  resp <- request(url) |> req_perform()
  j <- fromJSON(resp_body_string(resp))
  tibble(
    name = names(j$variables),
    label = map_chr(j$variables, "label", .default = NA_character_),
    concept = map_chr(j$variables, "concept", .default = NA_character_)
  ) |>
    arrange(name)
}

vars_2023 <- nes_list_vars(2023)
vars_2023 |> filter(grepl("NESTAB|RCPT|NRCPT|EMP", name))

# ---- Example: all WI counties, NAICS = 00, 2023 ----
wi_2023 <- nes_get(
  year = 2023,
  vars = c("NAME", "NESTAB", "NRCPTOT", "COUNTY", "STATE"),
  state = "55",
  county = "*",
  naics = "*",
  naics_var = "NAICS2022"
)

wi_2023$year <- 2023

# --- Milestone 2: Expand NES pull to all states for all years 2010-2023 ----
years <- 2010:2023
state_fips <- read_csv(
  file.path("0_inputs", "state_fips.csv"),
  col_types = cols(FIPS_CODE = col_character())
)
states <- state_fips$FIPS_CODE
vars_common <- c("NESTAB", "NRCPTOT")
naics_2digit <- c(
  "00", "11", "21", "22", "23", "31", "32", "33", "42",
  "44", "45", "48", "49", "51", "52", "53", "54", "55",
  "56", "61", "62", "71", "72", "81", "92"
)

out <- map_dfr(states, function(s) {
  map_dfr(years, function(y) {
    message("Pulling NES data for year ", y, ", state ", s)

    vars_y <- nes_list_vars(y)$name

    naics_var <- if ("NAICS2023" %in% vars_y) {
      "NAICS2023"
    } else if ("NAICS2022" %in% vars_y) {
      "NAICS2022"
    } else if ("NAICS2017" %in% vars_y) {
      "NAICS2017"
    } else if ("NAICS2012" %in% vars_y) {
      "NAICS2012"
    } else if ("NAICS2007" %in% vars_y) {
      "NAICS2007"
    } else if ("NAICS" %in% vars_y) {
      "NAICS"
    } else {
      NA_character_
    }

    if (is.na(naics_var)) {
      stop("No NAICS variable available for year ", y, " state ", s)
    }

    vars_use <- vars_common
    if (!is.na(naics_var)) vars_use <- c(vars_use, naics_var)

    map_dfr(naics_2digit, function(nc) {
      nes_get(
        year = y,
        vars = vars_use,
        state = s,
        county = "*",
        naics = nc,
        naics_var = naics_var
      ) |>
        rename(naics = all_of(naics_var)) |>
        mutate(year = y)
    })
  })
})

# --- Save RDS ---
saveRDS(out, file.path("2_processed_data", "NES_all.rds"))
