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
})

# Shared helper centralizes repeated local-data parsing and save logic.
source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

output_file <- file.path(
  charlie_bank_output_dir,
  "bank_fig04_branch_change_map.jpeg"
)


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

wi_counties <- load_wi_counties()

fig04_map <- wi_counties |>
  left_join(counties_2009, by = "county_upper") |>
  left_join(counties_2023, by = "county_upper") |>
  left_join(pop_2009, by = "county_upper") |>
  left_join(pop_2023, by = "county_upper") |>
  mutate(
    branches_per_10k_09 = (count_09 / pop_09) * 10000,
    branches_per_10k_23 = (count_23 / pop_23) * 10000,
    abs_change = branches_per_10k_23 - branches_per_10k_09
  )


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig04_plot <- ggplot(fig04_map) +
  geom_sf(aes(fill = abs_change), color = "white", linewidth = 0.25) +
  scale_fill_distiller(
    palette = "RdYlGn",
    direction = 1,
    na.value = "lightgray"
  ) +
  labs(
    title = "Figure 4: Change in Bank Branches per 10,000 Residents (2009-2023)",
    fill = "Change in branches\nper 10K",
    caption = "Data: FDIC Summary of Deposits and reviewed Census county population audit artifacts"
  ) +
  coord_sf(datum = NA) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig04_plot, output_file, width = 10, height = 12)
