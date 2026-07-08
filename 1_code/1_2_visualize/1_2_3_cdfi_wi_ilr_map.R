#///////////////////////////////////////////////////////////////////////////////
#----                 Wisconsin CDFI ILR Location Map                       ----
# File name:  1_2_3_cdfi_wi_ilr_map.R
# Author:     Codex
# Created:    2026-06-09
# Purpose:    Build a Wisconsin map of public ILR CDFI locations using the
#             latest available ZIP-based county assignment for each institution.
#///////////////////////////////////////////////////////////////////////////////

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(readxl)
  library(stringr)
  library(sf)
  library(ggplot2)
  library(scales)
  library(forcats)
})

output_dir <- file.path("agent-docs", "figures")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_path <- file.path(output_dir, "2026_06_09_cdfi_wi_ilr_map.png")

source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

ilr <- read_csv(
  file.path("0_inputs", "2017_CDFI", "releaseILR_fy03_15(1of1).csv"),
  show_col_types = FALSE
) |>
  transmute(
    org_id = as.character(org_id),
    fiscalyear = as.integer(fiscalyear),
    zip = str_pad(as.character(zip), width = 5, pad = "0"),
    fininst_type = as.character(fininstType),
    business_orig_amt = suppressWarnings(as.numeric(BUSINESS_orig)),
    business_orig_n = suppressWarnings(as.numeric(BUSINESS_orig_N))
  ) |>
  filter(!is.na(org_id), !is.na(zip), zip != "00000")

zip_county <- read_excel(
  file.path("0_inputs", "CORI", "HUD_crosswalks", "ZIP_COUNTY_122020.xlsx")
) |>
  transmute(
    zip = str_pad(as.character(ZIP), width = 5, pad = "0"),
    county_fips = str_pad(as.character(COUNTY), width = 5, pad = "0"),
    tot_ratio = as.numeric(TOT_RATIO)
  ) |>
  group_by(zip) |>
  slice_max(order_by = tot_ratio, n = 1, with_ties = FALSE) |>
  ungroup() |>
  filter(str_sub(county_fips, 1, 2) == "55")

wi_latest_orgs <- ilr |>
  group_by(org_id) |>
  slice_max(order_by = fiscalyear, n = 1, with_ties = FALSE) |>
  ungroup() |>
  inner_join(zip_county, by = "zip") |>
  mutate(
    broad_type = case_when(
      fininst_type == "LF" ~ "Loan fund",
      fininst_type %in% c("BANK", "BHOLD", "CU") ~ "Depository / holding company",
      TRUE ~ "Other"
    )
  )

wi_counties <- load_wi_counties() |>
  transmute(
    county_fips,
    county_name = county,
    county_upper,
    geometry
  ) |>
  st_transform(3071)

county_map <- wi_latest_orgs |>
  count(county_fips, name = "county_count") |>
  right_join(wi_counties, by = "county_fips") |>
  mutate(
    county_count = replace_na(county_count, 0L),
    count_bucket = case_when(
      county_count == 0L ~ "0",
      county_count == 1L ~ "1",
      county_count == 2L ~ "2",
      TRUE ~ "3+"
    ),
    count_bucket = factor(count_bucket, levels = c("0", "1", "2", "3+"))
  ) |>
  st_as_sf()

county_labels <- county_map |>
  filter(county_count >= 2L)

county_labels <- suppressWarnings(st_point_on_surface(county_labels))

county_label_coords <- st_coordinates(county_labels)

county_labels <- county_labels |>
  mutate(
    x = county_label_coords[, 1],
    y = county_label_coords[, 2],
    x = case_when(
      county_name == "Milwaukee" ~ x + 90000,
      county_name == "Vilas" ~ x + 30000,
      county_name == "Dane" ~ x - 90000,
      TRUE ~ x
    ),
    y = case_when(
      county_name == "Milwaukee" ~ y - 20000,
      county_name == "Vilas" ~ y + 30000,
      county_name == "Dane" ~ y - 20000,
      TRUE ~ y
    ),
    hjust = case_when(
      county_name == "Milwaukee" ~ 0,
      county_name == "Vilas" ~ 0.5,
      county_name == "Dane" ~ 1,
      TRUE ~ 0.5
    )
  ) |>
  mutate(
    label = paste0(county_name, "\n", county_count)
  )

subtitle_text <- paste0(
  comma(n_distinct(wi_latest_orgs$org_id)),
  " unique Wisconsin-based CDFIs observed in the public ILR, 2003-2015."
)

caption_text <- paste0(
  "Source: CDFI ILR public release and HUD ZIP-county crosswalk. ",
  "Public ILR data include ZIP code but not institution name, street address, or exact coordinates."
)

p <- ggplot(county_map) +
  geom_sf(aes(fill = count_bucket), color = "white", linewidth = 0.25) +
  geom_label(
    data = county_labels,
    aes(x = x, y = y, label = label, hjust = hjust),
    size = 3,
    linewidth = 0.15,
    fill = alpha("white", 0.9),
    color = "black"
  ) +
  scale_fill_manual(
    values = c(
      "0" = "grey95",
      "1" = "#fdd49e",
      "2" = "#fdbb84",
      "3+" = "#e34a33"
    ),
    name = "Unique CDFIs\nin county"
  ) +
  labs(
    title = "Wisconsin CDFI Incorporation by County",
    subtitle = subtitle_text,
    caption = caption_text
  ) +
  coord_sf(datum = NA, clip = "off") +
  charlie_map_theme() +
  theme(
    plot.title = element_text(size = 14),
    plot.subtitle = element_text(size = 10),
    plot.caption = element_text(size = 8, hjust = 0),
    legend.position = "right",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA),
    legend.key = element_rect(fill = "white", color = NA),
    legend.text = element_text(color = "black"),
    legend.title = element_text(color = "black")
  )

ggsave(
  filename = output_path,
  plot = p,
  width = 8.5,
  height = 6.25,
  dpi = 300,
  bg = "white"
)

message("Wrote Wisconsin CDFI ILR map -> ", output_path)
