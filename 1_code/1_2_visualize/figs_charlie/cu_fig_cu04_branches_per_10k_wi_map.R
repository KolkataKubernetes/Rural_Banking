#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  cu_fig_cu04_branches_per_10k_wi_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's credit-union figure CU-4. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig_cu04_branches_per_10k_wi_map.py
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
  charlie_cu_output_dir,
  "cu_fig_cu04_branches_per_10k_wi_map.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

cu_branch_2023 <- load_ncua_branch(2023) |>
  filter(PhysicalAddressStateCode == "WI")

county_column <- if ("PhysicalAddressCountyName" %in% names(cu_branch_2023)) {
  "PhysicalAddressCountyName"
} else {
  NA_character_
}

cu_counties <- if (!is.na(county_column)) {
  cu_branch_2023 |>
    count(!!sym(county_column), name = "cu_branches") |>
    rename(county = !!sym(county_column))
} else {
  readr::read_csv(
    file.path(charlie_ncua_dir, "ncua_master_final.csv"),
    show_col_types = FALSE
  ) |>
    filter(state == "WI") |>
    count(county, name = "cu_branches")
}

county_pop <- load_county_population_audit(2023)
wi_counties <- load_wi_counties()

fig_cu04_map <- cu_counties |>
  mutate(
    county = clean_county_name(county),
    county_upper = stringr::str_to_upper(county)
  ) -> cu_counties_clean

fig_cu04_map <- wi_counties |>
  left_join(cu_counties_clean, by = "county_upper") |>
  left_join(county_pop, by = "county_upper", suffix = c("", "_pop")) |>
  mutate(cu_per_10k = (cu_branches / pop) * 10000)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig_cu04_plot <- ggplot(fig_cu04_map) +
  geom_sf(aes(fill = cu_per_10k), color = "white", linewidth = 0.25) +
  scale_fill_distiller(
    palette = "Oranges",
    direction = 1,
    na.value = "lightgray"
  ) +
  labs(
    title = "Figure CU-4: Credit Union Branches per 10,000 Residents by County (2023)",
    fill = "CU Branches\nper 10K",
    caption = "Data: NCUA branch files and reviewed Census county population audit artifact"
  ) +
  coord_sf(datum = NA) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig_cu04_plot, output_file, width = 10, height = 12)
