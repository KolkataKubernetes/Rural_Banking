#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  cu_fig_cu05_headquarters_per_10k_wi_map.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-17
# Purpose:    Construct credit-union figure CU-5 from staged NCUA main-office
#             records. The figure shows Wisconsin credit union headquarters
#             per 10,000 residents by county in 2023.
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
  "cu_fig_cu05_headquarters_per_10k_wi_map.jpeg"
)

cb_county_dir <- file.path("0_inputs", "WI_CensusCB_Counties_2023")
cb_county_layer <- "cb_2023_us_county_500k"


# -----------------------------
# 1) Load inputs
# -----------------------------

cu_hq_2023 <- load_ncua_branch(2023) |>
  filter(
    PhysicalAddressStateCode == "WI",
    MainOffice == "Yes"
  ) |>
  count(PhysicalAddressCountyName, name = "n_hq") |>
  rename(county = PhysicalAddressCountyName) |>
  mutate(
    county = clean_county_name(county),
    county_upper = stringr::str_to_upper(county)
  )

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

fig_cu05_map <- wi_counties |>
  left_join(cu_hq_2023, by = "county_upper") |>
  left_join(county_pop, by = "county_upper", suffix = c("", "_pop")) |>
  mutate(
    n_hq = replace_na(n_hq, 0L),
    hq_per_10k = (n_hq / pop) * 10000,
    county_label = paste0(county, "\n", sprintf("%.2f", hq_per_10k))
  )

label_points <- fig_cu05_map |>
  st_point_on_surface()

total_hq <- sum(fig_cu05_map$n_hq, na.rm = TRUE)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig_cu05_plot <- ggplot(fig_cu05_map) +
  geom_sf(aes(fill = hq_per_10k), color = "black", linewidth = 0.25) +
  geom_sf_text(
    data = label_points,
    aes(label = county_label),
    size = 1.55,
    lineheight = 0.9,
    check_overlap = TRUE
  ) +
  scale_fill_distiller(
    palette = "Oranges",
    direction = 1,
    na.value = "lightgray"
  ) +
  annotate(
    "label",
    x = -92.8,
    y = 42.75,
    label = paste("Total WI CU HQs:", total_hq),
    size = 3
  ) +
  labs(
    title = "Figure CU-05: Credit Union Headquarters per 10,000 Residents by County (2023)",
    fill = "CU HQs\nper 10K",
    caption = "Data: NCUA branch files and reviewed Census county population audit artifact"
  ) +
  coord_sf(datum = NA, expand = FALSE) +
  charlie_map_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig_cu05_plot, output_file, width = 10, height = 12)
