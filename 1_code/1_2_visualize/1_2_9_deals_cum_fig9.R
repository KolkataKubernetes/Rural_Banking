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
  library(jsonlite)
  library(sf)
  library(scales)
})

options(tigris_use_cache = TRUE)

output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2"
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

# Match logic: filter `name_co` ending in "WI" and join to tigris counties by FIPS
# (`geoid_co` -> `GEOID`). JSON geometry is present but not used for matching.
formd_props <- as_tibble(formd_json$features$properties) |>
  filter(str_ends(name_co, "WI")) |>
  mutate(geoid_co = as.character(geoid_co))

# -----------------------------
# 2) Plot
# -----------------------------

wi_counties <- tigris::counties(state = "WI", cb = TRUE, year = 2023) |>
  st_transform(5070)

wi_map <- wi_counties |>
  mutate(geoid_co = GEOID) |>
  left_join(formd_props, by = "geoid_co") |>
  mutate(
    fill_bin = case_when(
      num_funded_entities == 0 ~ NA_character_,
      num_funded_entities <= 25 ~ "1–25",
      num_funded_entities <= 50 ~ "26–50",
      num_funded_entities <= 75 ~ "51–75",
      num_funded_entities <= 100 ~ "76–100",
      TRUE ~ ">100"
    ),
    fill_bin = factor(
      fill_bin,
      levels = c("1–25", "26–50", "51–75", "76–100", ">100")
    )
  )

ggplot(wi_map) +
  geom_sf(aes(fill = fill_bin), color = "white", linewidth = 0.2) +
  scale_fill_manual(
    values = c(
      "1–25" = scales::viridis_pal(option = "plasma")(4)[1],
      "26–50" = scales::viridis_pal(option = "plasma")(4)[2],
      "51–75" = scales::viridis_pal(option = "plasma")(4)[3],
      "76–100" = scales::viridis_pal(option = "plasma")(4)[4],
      ">100" = "black"
    ),
    na.value = "grey90",
    name = "Number of Form D\nfilings",
    drop = FALSE,
    guide = guide_legend(na.translate = TRUE)
  ) +
  labs(
    title    = "Form D Filing Count in Wisconsin by County",
    subtitle = "Since 2010; year coverage may not include 2025 (grey counties have zero filings)",
    caption  = "Source: CORI Form D interactive map totals"
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
  ) -> total_deals_cumulative

save_fig(
  p = total_deals_cumulative,
  filename = file.path(output_dir, "9_total_deals_cumulative.jpeg"),
  w = 16.5,
  h = 6.2
)
