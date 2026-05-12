#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig12_under100k_volume_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 12. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig12_under100k_volume_map.py
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
  "bank_fig12_under100k_volume_map.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

county_volume <- load_cra_2023_county_aggregates() |>
  group_by(County_FIPS) |>
  summarise(loans_u100k_amt = sum(Loans_U100k_Amt, na.rm = TRUE), .groups = "drop") |>
  mutate(county_fips = paste0("55", County_FIPS))

county_pop <- load_county_population_audit(2023)
wi_counties <- load_wi_counties()

fig12_map <- wi_counties |>
  left_join(county_volume, by = "county_fips") |>
  left_join(county_pop, by = "county_upper") |>
  mutate(volume_per_capita = loans_u100k_amt / pop)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig12_plot <- ggplot(fig12_map) +
  geom_sf(aes(fill = volume_per_capita), color = "white", linewidth = 0.25) +
  scale_fill_distiller(
    palette = "YlGnBu",
    direction = 1,
    na.value = "lightgray",
    labels = scales::label_dollar()
  ) +
  labs(
    title = "Figure 12: Under-$100K Loan Volume per Capita by County (2023)",
    fill = "$ per resident",
    caption = "Data: CRA aggregate files and reviewed Census county population audit artifact"
  ) +
  coord_sf(datum = NA) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig12_plot, output_file, width = 10, height = 12)
