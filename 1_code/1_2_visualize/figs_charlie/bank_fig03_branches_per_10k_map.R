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
})

# Shared helper centralizes repeated local-data parsing and save logic.
source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

output_file <- file.path(
  charlie_bank_output_dir,
  "bank_fig03_branches_per_10k_map.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

county_branches <- load_fdic_sod(2023) |>
  filter(STALPBR == "WI") |>
  count(CNTYNAMB, name = "count") |>
  mutate(county_upper = stringr::str_to_upper(CNTYNAMB))

county_pop <- load_county_population_audit(2023)
wi_counties <- load_wi_counties()

fig03_map <- wi_counties |>
  left_join(county_branches, by = c("county_upper")) |>
  left_join(county_pop, by = c("county_upper")) |>
  mutate(
    county_name = dplyr::coalesce(county.x, county.y),
    branches_per_10k = (count / pop) * 10000,
    bucket_label = cut(
      branches_per_10k,
      breaks = c(1.42, 2.06, 2.71, 3.62, 5.49, 7.44),
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
    bucket_label = forcats::fct_explicit_na(bucket_label, na_level = "No data"),
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
      paste0(county_name, "\n", sprintf("%.2f", branches_per_10k))
    )
  )

label_points <- fig03_map |>
  st_point_on_surface()


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig03_plot <- ggplot(fig03_map) +
  geom_sf(aes(fill = bucket_label), color = "white", linewidth = 0.25) +
  geom_sf_text(
    data = label_points,
    aes(label = county_label),
    size = 2.1,
    lineheight = 0.9,
    check_overlap = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "1.42 to 2.06" = "#deebf7",
      "2.07 to 2.71" = "#c6dbef",
      "2.72 to 3.62" = "#9ecae1",
      "3.63 to 5.49" = "#6baed6",
      "5.50 to 7.44" = "#3182bd",
      "No data" = "white"
    ),
    drop = FALSE
  ) +
  labs(
    title = "Figure 3: Bank Branches per 10,000 Residents by County (2023)",
    fill = "Branches per 10K",
    caption = "Data: FDIC Summary of Deposits and reviewed Census county population audit artifact"
  ) +
  coord_sf(datum = NA) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig03_plot, output_file, width = 10, height = 12)
