#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig04_branch_change_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 4. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig04_branch_change_map.py
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
  "bank_fig04_branch_change_map.jpeg"
)

cb_county_dir <- file.path("0_inputs", "WI_CensusCB_Counties_2023")
cb_county_layer <- "cb_2023_us_county_500k"


# -----------------------------
# 1) Load inputs
# -----------------------------

counties_2009 <- load_fdic_sod(2009) |>
  filter(STALPBR == "WI") |>
  count(CNTYNAMB, name = "count_09") |>
  mutate(county_upper = stringr::str_to_upper(CNTYNAMB))

counties_2023 <- load_fdic_sod(2023) |>
  filter(STALPBR == "WI") |>
  count(CNTYNAMB, name = "count_23") |>
  mutate(county_upper = stringr::str_to_upper(CNTYNAMB))

pop_2009 <- load_county_population_audit(2009) |>
  transmute(county_upper, pop_09 = pop)

pop_2023 <- load_county_population_audit(2023) |>
  transmute(county_upper, pop_23 = pop)

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

fig04_map <- wi_counties |>
  left_join(counties_2009, by = "county_upper") |>
  left_join(counties_2023, by = "county_upper") |>
  left_join(pop_2009, by = "county_upper") |>
  left_join(pop_2023, by = "county_upper") |>
  mutate(
    branches_per_10k_09 = (count_09 / pop_09) * 10000,
    branches_per_10k_23 = (count_23 / pop_23) * 10000,
    abs_change = branches_per_10k_23 - branches_per_10k_09,
    county_name = county,
    change_bucket = case_when(
      is.na(abs_change) ~ "No data",
      abs_change > 0 ~ "Increase",
      abs_change <= 0 & abs_change > -1 ~ "0 to -1",
      abs_change <= -1 & abs_change > -2 ~ "-1 to -2",
      abs_change <= -2 & abs_change > -4 ~ "-2 to -4",
      abs_change <= -4 ~ "-4 or less"
    ),
    change_bucket = factor(
      change_bucket,
      levels = c("Increase", "0 to -1", "-1 to -2", "-2 to -4", "-4 or less", "No data")
    ),
    positive_label = case_when(
      abs_change > 0 ~ paste0(county_name, "\n+", sprintf("%.2f", abs_change)),
      TRUE ~ NA_character_
    )
  )

positive_points <- fig04_map |>
  filter(abs_change > 0) |>
  st_point_on_surface()


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig04_plot <- ggplot(fig04_map) +
  geom_sf(aes(fill = change_bucket), color = "black", linewidth = 0.25) +
  geom_sf_text(
    data = positive_points,
    aes(label = positive_label),
    size = 1.8,
    fontface = "bold",
    lineheight = 0.9,
    check_overlap = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Increase" = "#2b8cbe",
      "0 to -1" = "#fff7bc",
      "-1 to -2" = "#fee391",
      "-2 to -4" = "#fdae6b",
      "-4 or less" = "#d94801",
      "No data" = "white"
    ),
    drop = FALSE
  ) +
  labs(
    title = "Figure 4: Change in Bank Branches per 10,000 Residents (2009-2023)",
    fill = "Change in branches\nper 10K"
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

save_charlie_fig(fig04_plot, output_file, width = 7.25, height = 9)
