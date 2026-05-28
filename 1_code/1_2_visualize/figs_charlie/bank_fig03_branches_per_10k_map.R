#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig03_branches_per_10k_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 3. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig03_branches_per_10k_map.py
#///////////////////////////////////////////////////////////////////////////////


# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(grid)
})

# Shared helper centralizes repeated local-data parsing and save logic.
source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

output_file <- file.path(
  charlie_bank_output_dir,
  "bank_fig03_branches_per_10k_map.jpeg"
)

cb_county_dir <- file.path("0_inputs", "WI_CensusCB_Counties_2023")
cb_county_layer <- "cb_2023_us_county_500k"


# -----------------------------
# 1) Load inputs
# -----------------------------

county_branches <- load_fdic_sod(2023) |>
  filter(STALPBR == "WI") |>
  count(CNTYNAMB, name = "count") |>
  mutate(county_upper = stringr::str_to_upper(CNTYNAMB))

county_pop <- load_county_population_audit(2023)
wi_counties <- st_read(
  dsn = cb_county_dir,
  layer = cb_county_layer,
  quiet = TRUE
) |>
  filter(STATEFP == "55") |>
  transmute(
    county = clean_county_name(NAME),
    county_upper = stringr::str_to_upper(county),
    county_fips = GEOID,
    geometry
  ) |>
  st_transform(3071)

fig03_map <- wi_counties |>
  left_join(county_branches, by = c("county_upper")) |>
  left_join(county_pop, by = c("county_upper")) |>
  mutate(
    county_name = dplyr::coalesce(county.x, county.y),
    branches_per_10k = (count / pop) * 10000,
    bucket_label = cut(
      branches_per_10k,
      breaks = c(1.42, 2.06, 2.71, 3.62, 5.49, Inf),
      include.lowest = TRUE,
      labels = c(
        "1.42 to 2.06",
        "2.07 to 2.71",
        "2.72 to 3.62",
        "3.63 to 5.49",
        "5.50 to 7.44"
      )
    )
  ) |>
  mutate(
    bucket_label = forcats::fct_na_value_to_level(bucket_label, level = "No data"),
    bucket_label = factor(
      bucket_label,
      levels = c(
        "1.42 to 2.06",
        "2.07 to 2.71",
        "2.72 to 3.62",
        "3.63 to 5.49",
        "5.50 to 7.44",
        "No data"
      )
    ),
    county_label = dplyr::if_else(
      is.na(branches_per_10k),
      county_name,
      paste0(sprintf("%.2f", branches_per_10k), "\n", county_name)
    )
  )

label_points <- fig03_map |>
  st_point_on_surface()


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig03_plot <- ggplot(fig03_map) +
  geom_sf(aes(fill = bucket_label), color = "black", linewidth = 0.25) +
  geom_sf_text(
    data = label_points,
    aes(label = county_label),
    size = 1.55,
    lineheight = 0.9,
    check_overlap = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "1.42 to 2.06" = "#fff5eb",
      "2.07 to 2.71" = "#fdd0a2",
      "2.72 to 3.62" = "#fdae6b",
      "3.63 to 5.49" = "#f16913",
      "5.50 to 7.44" = "#8c2d04",
      "No data" = "white"
    ),
    drop = FALSE
  ) +
  labs(
    title = "Figure 3: Bank Branches per 10,000 Residents, Wisconsin Counties (2023)",
    fill = "Branches per 10k Residents"
  ) +
  coord_sf(datum = NA, expand = FALSE) +
  charlie_map_theme() +
  theme(
    plot.title = element_text(size = 10.5, hjust = 0.5),
    legend.position = "right",
    legend.justification = "center",
    legend.key.height = unit(0.14, "in"),
    legend.text = element_text(size = 6.8),
    legend.title = element_text(size = 7.2),
    legend.background = element_blank(),
    legend.box.margin = margin(0, 0, 0, 6),
    plot.margin = margin(8, 16, 8, 8)
  )


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig03_plot, output_file, width = 7.25, height = 9)
