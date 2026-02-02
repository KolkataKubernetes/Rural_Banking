#///////////////////////////////////////////////////////////////////////////////
#----     Ingest: US Census County Business Patterns            ----
# File name:  census_CBP.R
# Author:     Inder Majumdar
# Created:    2026-02-02
# Purpose:    Ingest US Census County Business Pattern Data
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

# ---- Core fetch function ----
cbp_get <- function(year,
                    vars = c("NAME", "ESTAB", "EMP", "PAYANN"),
                    state = NULL,         # e.g., "55" for Wisconsin
                    county = "*",         # "*" for all counties; or "025" for Dane County
                    naics = NULL,         # e.g., "11" or "5413" or "541330"
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
  
  # Optional filters (CBP supports NAICS2017, LFO, EMPSZES, etc., depending on year)
  if (!is.null(naics)) query$NAICS2017 <- naics
  if (!is.null(lfo))   query$LFO <- lfo
  if (!is.null(empsz)) query$EMPSZES <- empsz
  
  # API key is optional for small requests, but recommended.
  if (!is.na(key) && nzchar(key)) query$key <- key
  
  resp <- request(base) |>
    req_url_query(!!!query) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()
  
  if (resp_status(resp) != 200) {
    stop("Census API request failed: HTTP ", resp_status(resp), "\n",
         resp_body_string(resp))
  }
  
  # Census API returns JSON as an array-of-arrays: first row is header.
  raw <- resp_body_string(resp)
  arr <- fromJSON(raw)
  
  out <- as_tibble(arr[-1, , drop = FALSE])
  names(out) <- arr[1, ]
  
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

vars_2011 <- cbp_list_vars(2011)
vars_2010 |> filter(grepl("EMP|ESTAB|PAY", name))

# ---- Example: all WI counties, all NAICS (may be large) ----
wi_all <- cbp_get(
  year  = 2015,
  vars  = c("ESTAB", "EMP", "PAYANN"),
  state = "55",
  county = "*",
  naics = "00"
)

# --- Collect all Wisconsin Data from 2010 to present

