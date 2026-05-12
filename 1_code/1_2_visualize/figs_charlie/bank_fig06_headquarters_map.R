#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig06_headquarters_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 6. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig06_headquarters_map.py
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
  "bank_fig06_headquarters_map.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

hq_counts <- load_fdic_sod(2024) |>
  filter(as.character(BRNUM) == "0", STALP == "WI") |>
  count(CNTYNAMB, name = "n_hq") |>
  mutate(county_upper = stringr::str_to_upper(CNTYNAMB))

wi_counties <- load_wi_counties() |>
  left_join(hq_counts, by = "county_upper") |>
  mutate(n_hq = replace_na(n_hq, 0))

total_hq <- sum(wi_counties$n_hq, na.rm = TRUE)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig06_plot <- ggplot(wi_counties) +
  geom_sf(aes(fill = n_hq), color = "white", linewidth = 0.25) +
  scale_fill_distiller(
    palette = "YlOrRd",
    direction = 1,
    na.value = "lightgray"
  ) +
  annotate(
    "label",
    x = -92.7,
    y = 42.7,
    label = paste("Total WI bank HQs:", total_hq),
    size = 3
  ) +
  labs(
    title = "Figure 6: Bank Headquarters by County (2024)",
    fill = "Number of\nBank HQs",
    caption = "Data: FDIC Summary of Deposits"
  ) +
  coord_sf(datum = NA) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig06_plot, output_file, width = 10, height = 12)
