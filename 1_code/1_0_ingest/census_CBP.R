#///////////////////////////////////////////////////////////////////////////////
#----     Ingest: US Census County Business Patterns            ----
# File name:  census_CBP.R
# Author:     Inder Majumdar
# Created:    2026-02-02
# Purpose:    Ingest US Census County Business Pattern Data

# Update: 02/02/2026: Tessa said to use Business Formation Statistics.
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
library(readxl)

# ---- Census API key (optional) ----
load_census_key <- function(path = file.path("0_inputs", "census_apikey.md")) {
  if (!file.exists(path)) return(NA_character_)
  key <- readLines(path, warn = FALSE)
  key <- trimws(paste(key, collapse = ""))
  if (!nzchar(key)) return(NA_character_)
  key
}

# ---- Core fetch function ----
cbp_get <- function(year,
                    vars = c("NAME", "ESTAB", "EMP", "PAYANN"),
                    state = NULL,         # e.g., "55" for Wisconsin
                    county = "*",         # "*" for all counties; or "025" for Dane County
                    naics = NULL,         # e.g., "11" or "5413" or "541330"
                    naics_var = "NAICS2017",
                    lfo = NULL,           # legal form of org (optional)
                    empsz = NULL,         # employment-size class (optional)
                    key = Sys.getenv("CENSUS_API_KEY", unset = NA)) {
  
  base <- paste0("https://api.census.gov/data/", year, "/cbp")
  
  # The Census API uses `get=var1,var2,...` plus geography via `for=` and `in=`
  # County-level: for=county:<code or *> & in=state:<FIPS>
  if (is.null(state)) stop("Provide a 2-digit state FIPS code (e.g., '55' for WI).")
  
  query <- list(
    get = paste(vars, collapse = ","),
    `for` = paste0("county:", county),
    `in`  = paste0("state:", state)
  )
  
  # Optional filters (CBP supports NAICS* variants, LFO, EMPSZES, etc., depending on year)
  if (!is.null(naics)) query[[naics_var]] <- naics
  if (!is.null(lfo))   query$LFO <- lfo
  if (!is.null(empsz)) query$EMPSZES <- empsz
  
  # API key is optional for small requests, but recommended.
  if (is.na(key) || !nzchar(key)) key <- load_census_key()
  if (!is.na(key) && nzchar(key)) query$key <- key
  
  resp <- request(base) |>
    req_url_query(!!!query) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()
  
  make_empty <- function(cols) {
    num_cols <- c("ESTAB", "EMP", "PAYANN", "PAYQTR1")
    col_list <- lapply(cols, function(x) {
      if (x %in% num_cols) {
        numeric()
      } else {
        character()
      }
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
  
  # Census API returns JSON as an array-of-arrays: first row is header.
  raw_bytes <- resp_body_raw(resp)
  if (length(raw_bytes) == 0) {
    out_cols <- c(vars, "state", "county")
    return(make_empty(out_cols))
  }
  raw <- rawToChar(raw_bytes)
  arr <- fromJSON(raw)
  
  out <- as_tibble(arr[-1, , drop = FALSE], .name_repair = "minimal")
  names(out) <- make.unique(arr[1, ])
  
  # Try to parse numeric columns where it makes sense
  # (CBP has suppression / flags in some columns; parsing may yield NA where non-numeric.)
  out <- out |>
    mutate(across(any_of(c("ESTAB","EMP","PAYANN","PAYQTR1")), readr::parse_number))
  
  out
}


cbp_list_vars <- function(year) {
  url <- paste0("https://api.census.gov/data/", year, "/cbp/variables.json")
  resp <- request(url) |> req_perform()
  j <- fromJSON(resp_body_string(resp))
  tibble(
    name  = names(j$variables),
    label = map_chr(j$variables, "label", .default = NA_character_),
    concept = map_chr(j$variables, "concept", .default = NA_character_)
  ) |>
    arrange(name)
}

vars_2023 <- cbp_list_vars(2023)
vars_2023 |> filter(grepl("EMP|ESTAB|PAY", name))

# ---- Example: all WI counties, NAICS = 00, 2023 ----
wi_2023 <- cbp_get(
  year  = 2023,
  vars  = c("NAME","ESTAB", "EMP", "PAYANN"),
  state = "55",
  county = "*",
  naics = "*"
)

wi_2023$year <- 2023

# --- Collect all Wisconsin Data from 2010 to present, call the dataframe WI All

## Get State FIPS code filepath:
state_fips <- read_csv(file.path("0_inputs","state_fips.csv"))

years <- 2010:2023
states <- c(state_fips$FIPS_CODE)
vars_common <- c("ESTAB", "EMP", "PAYANN")
naics_filter <- "00"
naics_filter_all <- "*"
naics_2digit <- c(
  "00", "11", "21", "22", "23", "31", "32", "33", "42",
  "44", "45", "48", "49", "51", "52", "53", "54", "55",
  "56", "61", "62", "71", "72", "81", "92"
)

out <- map_dfr(states, function(s) {
  map_dfr(years, function(y) {
    message("Pulling CBP data for year", y,",","state ",s)
    vars_y <- cbp_list_vars(y)$name
    naics_var <- if ("NAICS2022" %in% vars_y) {
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
    naics_list <- naics_2digit
    vars_use <- vars_common
    if (!is.na(naics_var)) vars_use <- c(vars_use, naics_var)
    map_dfr(naics_list, function(nc) {
      cbp_get(
        year  = y,
        vars  = vars_use,
        state = s,
        county = "*",
        naics = nc,
        naics_var = naics_var
      ) |>
        mutate(year = y)
    })
  })
})


wi_all <- map_dfr(years, function(y) {
  message("Pulling CBP data for ", y)
  vars_y <- cbp_list_vars(y)$name
  naics_var <- if ("NAICS2022" %in% vars_y) {
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
    stop("No NAICS variable available for year ", y, " state 55")
  }
  vars_use <- vars_common
  if (!is.na(naics_var)) vars_use <- c(vars_use, naics_var)
  cbp_get(
    year  = y,
    vars  = vars_use,
    state = "55",
    county = "*",
    naics = naics_filter,
    naics_var = naics_var
  ) |>
    mutate(year = y)
})

# ---- Join RUCC to classify metro vs rural (RUCC 1-3 = metro, else rural) ----
rucc <- readxl::read_excel(file.path("0_inputs", "Ruralurbancontinuumcodes2023.xlsx"))

out <- out |>
  mutate(
    county_fips = paste0(
      sprintf("%02d", as.integer(state)),
      sprintf("%03d", as.integer(county))
    )
  ) |>
  left_join(
    rucc |> mutate(RUCC_2023 = as.integer(RUCC_2023)) |> select(FIPS, RUCC_2023),
    by = c("county_fips" = "FIPS")
  ) |>
  mutate(
    rurality = if_else(RUCC_2023 %in% c(1, 2, 3), "metro", "rural")
  )

# ---- Aggregate to state x year x NAICS (sum across counties) ----
out <- out |>
  mutate(
    naics = dplyr::coalesce(
      dplyr::if_else("NAICS2022" %in% names(out), as.character(NAICS2022), NA_character_),
      dplyr::if_else("NAICS2017" %in% names(out), as.character(NAICS2017), NA_character_),
      dplyr::if_else("NAICS2012" %in% names(out), as.character(NAICS2012), NA_character_),
      dplyr::if_else("NAICS2007" %in% names(out), as.character(NAICS2007), NA_character_),
      dplyr::if_else("NAICS" %in% names(out), as.character(NAICS), NA_character_)
    )
  )

state_year_naics <- out |>
  group_by(state, year, naics) |>
  summarise(
    ESTAB = sum(ESTAB, na.rm = TRUE),
    EMP = sum(EMP, na.rm = TRUE),
    PAYANN = sum(PAYANN, na.rm = TRUE),
    .groups = "drop"
  )


# --- Save RDS 

saveRDS(out,file.path("2_processed_data","CBP_all.rds"))




