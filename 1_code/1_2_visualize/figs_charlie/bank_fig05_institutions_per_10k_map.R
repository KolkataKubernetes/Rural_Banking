#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig05_institutions_per_10k_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 5. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig05_institutions_per_10k_map.py
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
  "bank_fig05_institutions_per_10k_map.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

county_institutions <- load_fdic_sod(2023) |>
  filter(STALPBR == "WI") |>
  group_by(CNTYNAMB) |>
  summarise(n_inst = n_distinct(NAMEFULL), .groups = "drop") |>
  mutate(county_upper = stringr::str_to_upper(CNTYNAMB))

county_pop <- load_county_population_audit(2023)
wi_counties <- load_wi_counties()

fig05_map <- wi_counties |>
  left_join(county_institutions, by = "county_upper") |>
  left_join(county_pop, by = "county_upper") |>
  mutate(inst_per_10k = (n_inst / pop) * 10000)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig05_plot <- ggplot(fig05_map) +
  geom_sf(aes(fill = inst_per_10k), color = "white", linewidth = 0.25) +
  scale_fill_distiller(
    palette = "Blues",
    direction = 1,
    na.value = "lightgray"
  ) +
  labs(
    title = "Figure 5: Banking Institutions per 10,000 Residents by County (2023)",
    fill = "Institutions\nper 10K",
    caption = "Data: FDIC Summary of Deposits and reviewed Census county population audit artifact"
  ) +
  coord_sf(datum = NA) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig05_plot, output_file, width = 10, height = 12)
