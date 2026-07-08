#///////////////////////////////////////////////////////////////////////////////
#----                 Wisconsin CDFI TLR Activity Map                      ----
# File name:  1_2_3b_cdfi_wi_tlr_map.R
# Author:     Codex
# Created:    2026-06-09
# Purpose:    Build a Wisconsin county map for the latest public TLR release,
#             showing both how many distinct CDFIs were active in each county
#             and the corresponding business lending volume.
#///////////////////////////////////////////////////////////////////////////////

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(ggplot2)
  library(scales)
  library(patchwork)
})

output_dir <- file.path("agent-docs", "figures")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_path <- file.path(output_dir, "2026_06_09_cdfi_wi_tlr_2022_map.png")

source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

tlr <- readRDS(file.path("2_processed_data", "cdfi_tlr_harmonized.rds"))

wi_tlr_2022 <- tlr |>
  filter(
    source_release == "2022_CDFI_tlr_release",
    report_year == 2022,
    is_business,
    state_fips == "55",
    !is.na(county_fips),
    nchar(county_fips) == 5
  )

county_activity <- wi_tlr_2022 |>
  group_by(county_fips) |>
  summarise(
    active_cdfis = n_distinct(org_id),
    lending_volume = sum(allocated_amount_county, na.rm = TRUE),
    loans = sum(allocated_loan_count_county, na.rm = TRUE),
    .groups = "drop"
  )

wi_counties <- load_wi_counties() |>
  transmute(
    county_fips,
    county_name = county,
    county_upper,
    geometry
  ) |>
  st_transform(3071)

county_map <- wi_counties |>
  left_join(county_activity, by = "county_fips") |>
  mutate(
    active_cdfis = coalesce(active_cdfis, 0L),
    lending_volume = coalesce(lending_volume, 0),
    loans = coalesce(loans, 0),
    volume_millions = lending_volume / 1e6,
    cdfi_bucket = case_when(
      active_cdfis == 0L ~ "0",
      active_cdfis == 1L ~ "1",
      active_cdfis <= 3L ~ "2-3",
      active_cdfis <= 6L ~ "4-6",
      TRUE ~ "7+"
    ),
    cdfi_bucket = factor(cdfi_bucket, levels = c("0", "1", "2-3", "4-6", "7+")),
    volume_bucket = case_when(
      lending_volume == 0 ~ "$0",
      volume_millions < 1 ~ "<$1M",
      volume_millions < 5 ~ "$1M-$5M",
      volume_millions < 15 ~ "$5M-$15M",
      TRUE ~ "$15M+"
    ),
    volume_bucket = factor(
      volume_bucket,
      levels = c("$0", "<$1M", "$1M-$5M", "$5M-$15M", "$15M+")
    )
  ) |>
  st_as_sf()

subtitle_text <- paste0(
  comma(n_distinct(wi_tlr_2022$org_id)),
  " reporting CDFIs made Wisconsin business loans in the 2022 public TLR, ",
  "reaching ",
  comma(sum(county_map$active_cdfis > 0)),
  " counties and about $",
  comma(round(sum(county_map$lending_volume) / 1e6, 1)),
  " million in allocated volume."
)

caption_text <- paste0(
  "Source: 2022 CDFI public TLR, harmonized county allocations, and Wisconsin ",
  "county shapefiles. Counts reflect distinct reporting institutions lending ",
  "into each county; volume sums county-allocated business lending."
)

count_plot <- ggplot(county_map) +
  geom_sf(aes(fill = cdfi_bucket), color = "white", linewidth = 0.25) +
  scale_fill_manual(
    values = c(
      "0" = "grey95",
      "1" = "#fee8c8",
      "2-3" = "#fdbb84",
      "4-6" = "#e34a33",
      "7+" = "#b30000"
    ),
    name = "Active CDFIs"
  ) +
  labs(title = "Distinct CDFIs Lending Into County") +
  coord_sf(datum = NA) +
  charlie_map_theme() +
  theme(
    plot.title = element_text(size = 12),
    legend.position = "right",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA),
    legend.key = element_rect(fill = "white", color = NA)
  )

volume_plot <- ggplot(county_map) +
  geom_sf(aes(fill = volume_bucket), color = "white", linewidth = 0.25) +
  scale_fill_manual(
    values = c(
      "$0" = "grey95",
      "<$1M" = "#fee8c8",
      "$1M-$5M" = "#fdbb84",
      "$5M-$15M" = "#e34a33",
      "$15M+" = "#b30000"
    ),
    name = "Business lending volume"
  ) +
  labs(title = "Allocated Business Lending Volume") +
  coord_sf(datum = NA) +
  charlie_map_theme() +
  theme(
    plot.title = element_text(size = 12),
    legend.position = "right",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA),
    legend.key = element_rect(fill = "white", color = NA)
  )

p <- count_plot + volume_plot +
  plot_layout(ncol = 2) +
  plot_annotation(
    title = "Wisconsin CDFI Business Lending by County",
    subtitle = subtitle_text,
    caption = caption_text
  )

ggsave(
  filename = output_path,
  plot = p,
  width = 11,
  height = 6.5,
  dpi = 300,
  bg = "white"
)

message("Wrote Wisconsin CDFI TLR activity map -> ", output_path)
