#///////////////////////////////////////////////////////////////////////////////
#----           Figure 9: Form D Filing Count by Wisconsin County          ----
# File name:  1_2_9_deals_cum_fig9.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Map total Form D filing counts by Wisconsin county.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(scales)
})

options(tigris_use_cache = TRUE)

output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# --- Helper to save with consistent spec
save_fig <- function(p, filename, w = 7, h = 4.2, dpi = 320) {
  ggsave(filename, p, width = w, height = h, dpi = dpi, bg = "white")
}

# -----------------------------
# 1) Load intermediate data
# -----------------------------

formd_wi_county <- readRDS(file.path("2_processed_data", "formd_wi_county.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

wi_counties <- tigris::counties(state = "WI", cb = TRUE, year = 2023) |>
  st_transform(5070)

wi_map <- wi_counties |>
  mutate(county_fips = GEOID) |>
  left_join(formd_wi_county, by = "county_fips")

ggplot(wi_map) +
  geom_sf(aes(fill = n_filings), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    option = "plasma",
    na.value = "grey90",
    labels = label_comma(),
    name = "Number of Form D\nfilings"
  ) +
  labs(
    title    = "Form D Filing Count in Wisconsin by County",
    subtitle = "Number of filings, 2015-2014",
    caption  = "Source: SEC Form D (via dform); author calculations"
  ) +
  coord_sf() +
  theme_minimal(base_size = 12) -> total_deals_cumulative

save_fig(
  p = total_deals_cumulative,
  filename = file.path(output_dir, "9_total_deals_cumulative.jpeg")
)
