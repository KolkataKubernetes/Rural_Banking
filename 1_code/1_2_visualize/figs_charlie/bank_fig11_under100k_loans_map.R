#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig11_under100k_loans_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 11. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig11_under100k_loans_map.py
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
  "bank_fig11_under100k_loans_map.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

county_loans <- load_cra_2023_county_aggregates() |>
  group_by(County_FIPS) |>
  summarise(loans_u100k_num = sum(Loans_U100k_Num, na.rm = TRUE), .groups = "drop") |>
  mutate(county_fips = paste0("55", County_FIPS))

county_pop <- load_county_population_audit(2023)
wi_counties <- load_wi_counties()

fig11_map <- wi_counties |>
  left_join(county_loans, by = "county_fips") |>
  left_join(county_pop, by = "county_upper") |>
  mutate(loans_per_10k = (loans_u100k_num / pop) * 10000)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig11_plot <- ggplot(fig11_map) +
  geom_sf(aes(fill = loans_per_10k), color = "white", linewidth = 0.25) +
  scale_fill_distiller(
    palette = "YlOrRd",
    direction = 1,
    na.value = "lightgray"
  ) +
  labs(
    title = "Figure 11: Under-$100K Small Business Loans per 10K Residents by County (2023)",
    fill = "Loans per\n10K residents",
    caption = "Data: CRA aggregate files and reviewed Census county population audit artifact"
  ) +
  coord_sf(datum = NA) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig11_plot, output_file, width = 10, height = 12)
