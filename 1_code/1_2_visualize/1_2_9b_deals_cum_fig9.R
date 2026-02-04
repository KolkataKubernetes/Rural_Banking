#///////////////////////////////////////////////////////////////////////////////
#----        Figure 9b: Form D Filing Count (BFS-normalized)              ----
# File name:  1_2_9b_deals_cum_fig9.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-02-03
# Purpose:    Map Form D filing counts per BFS applications by county.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(jsonlite)
  library(sf)
  library(scales)
})

options(tigris_use_cache = TRUE)

output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_02_03"
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

formd_json <- fromJSON(
  file.path("0_inputs", "upstream", "formd-interactive-map", "src", "data", "formd_map.json")
)

formd_props <- as_tibble(formd_json$features$properties) |>
  filter(str_ends(name_co, "WI")) |>
  mutate(geoid_co = as.character(geoid_co))

bfs <- readRDS(file.path("2_processed_data", "BFS_county.rds")) |>
  mutate(
    state_fips = stringr::str_pad(as.character(state_fips), width = 2, pad = "0"),
    county_fips_full = stringr::str_pad(as.character(county_fips_full), width = 5, pad = "0")
  )

bfs_wi_county <- bfs |>
  filter(state_fips == "55", year >= 2010) |>
  group_by(county_fips_full) |>
  summarise(sum_apps = sum(business_app, na.rm = TRUE), .groups = "drop")

formd_props <- formd_props |>
  left_join(bfs_wi_county, by = c("geoid_co" = "county_fips_full")) |>
  mutate(
    per_thousand_apps = num_funded_entities / (sum_apps / 1000)
  )

# -----------------------------
# 2) Plot
# -----------------------------

wi_counties <- tigris::counties(state = "WI", cb = TRUE, year = 2023) |>
  st_transform(5070)

wi_map <- wi_counties |>
  mutate(geoid_co = GEOID) |>
  left_join(formd_props, by = "geoid_co")

ggplot(wi_map) +
  geom_sf(aes(fill = per_thousand_apps), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    option = "plasma",
    na.value = "grey90",
    labels = label_number(accuracy = 1),
    name = "Form D filings\nper 1,000 business apps"
  ) +
  labs(
    title    = "Form D Filing Count in Wisconsin by County",
    subtitle = "Since 2010; per 1,000 business applications",
    caption  = "Source: CORI Form D interactive map totals (since 2010). Denominator: BFS business applications summed 2010–2024."
  ) +
  coord_sf() +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    legend.box = "vertical",
    legend.title.align = 0.5,
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    plot.margin = margin(10, 10, 18, 10)
  ) -> total_deals_bfs

save_fig(
  p = total_deals_bfs,
  filename = file.path(output_dir, "9b_9_total_deals_cumulative.jpeg"),
  w = 16.5,
  h = 6.2
)
