#///////////////////////////////////////////////////////////////////////////////
#----     Ingest: US Census Business Formation Statistics      ----
# File name:  census_BFS.R
# Author:     Inder Majumdar
# Created:    2026-02-02
# Purpose:    Ingest US Census Business Formation Statistics (county-level)
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

## Packages
library('tidyverse')

# -----------------------------
# 1) Ingest
# -----------------------------

bfs <- readxl::read_excel(file.path("0_inputs","bfs_county_apps_annual.xlsx"))

# -----------------------------
# 2) Wide to long, using year
# -----------------------------

bfs_long <- bfs %>%
  pivot_longer(
    cols = matches("^\\d{4}$"),
    names_to = "year",
    values_to = "business_app"
  ) |>
  mutate(
    State = as.character(State),
    County = as.character(County),
    year = as.integer(year),
    business_app = as.numeric(business_app)
  )

# -----------------------------
# 3) Join RUCC for urban/rural definition
# -----------------------------
rucc <- readxl::read_excel(file.path("0_inputs", "Ruralurbancontinuumcodes2023.xlsx"))

bfs_long <- bfs_long |>
  mutate(
    state_fips = stringr::str_pad(as.character(state_fips), width = 2, pad = "0"),
    county_fips = stringr::str_pad(as.character(county_fips), width = 3, pad = "0"),
    county_fips_full = paste0(state_fips, county_fips)
  ) |>
  left_join(
    rucc |>
      mutate(RUCC_2023 = as.integer(RUCC_2023)) |>
      select(FIPS, RUCC_2023),
    by = c("county_fips_full" = "FIPS")
  ) |>
  mutate(
    rurality = if_else(RUCC_2023 %in% c(1, 2, 3), "metro", "rural")
  )

# Save as RDS 

saveRDS(bfs_long,file.path("2_processed_data","BFS_county.rds"))


