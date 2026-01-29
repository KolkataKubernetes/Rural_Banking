#///////////////////////////////////////////////////////////////////////////////
#----                Figure 3: VC Deal Size (WI vs US)                    ----
# File name:  1_2_3_vc_dealsize_fig3.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot venture capital deal size time series comparisons.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# --- Minimal, clean theme
theme_im <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_line(linewidth = 0.3),
      panel.grid.major.y = element_line(linewidth = 0.3),
      legend.position = "top",
      legend.title = element_text(face = "bold"),
      plot.title = element_text(face = "bold"),
      axis.title = element_text(face = "bold")
    )
}

# --- Helper to save with consistent spec
save_fig <- function(p, filename, w = 7, h = 4.2, dpi = 320) {
  ggsave(filename, p, width = w, height = h, dpi = dpi, bg = "white")
}

# -----------------------------
# 1) Load intermediate data
# -----------------------------

count_ts_data <- readRDS(file.path("2_processed_data", "count_ts_data.rds"))
vol_ts_data <- readRDS(file.path("2_processed_data", "vol_ts_data.rds"))

avg_label <- "2015–2025 average"
count_totals <- count_ts_data |>
  filter(year >= 2015, year <= 2025) |>
  summarise(
    dealcount_national = sum(dealcount_national, na.rm = TRUE),
    dealcount_national_nonoutlier = sum(dealcount_national_nonoutlier, na.rm = TRUE),
    dealcount_midwest = sum(dealcount_midwest, na.rm = TRUE),
    dealcount_wi = sum(dealcount_wi, na.rm = TRUE)
  )

vol_totals <- vol_ts_data |>
  filter(year >= 2015, year <= 2025) |>
  summarise(
    dealvol_national = sum(dealvol_national, na.rm = TRUE),
    dealvol_national_nonoutlier = sum(dealvol_national_nonoutlier, na.rm = TRUE),
    dealvol_midwest = sum(dealvol_midwest, na.rm = TRUE),
    dealvol_wi = sum(dealvol_wi, na.rm = TRUE)
  )

avg_data <- tibble(
  series = c(
    "National",
    "National (excl. CA, MA, NY)",
    "Midwest (excl. WI)",
    "Wisconsin"
  ),
  dealsize = c(
    vol_totals$dealvol_national / count_totals$dealcount_national,
    vol_totals$dealvol_national_nonoutlier / count_totals$dealcount_national_nonoutlier,
    vol_totals$dealvol_midwest / count_totals$dealcount_midwest,
    vol_totals$dealvol_wi / count_totals$dealcount_wi
  )
) |>
  mutate(
    series = factor(
      series,
      levels = c(
        "National",
        "National (excl. CA, MA, NY)",
        "Midwest (excl. WI)",
        "Wisconsin"
      )
    )
  )

nat_avg <- avg_data |>
  filter(series == "National") |>
  summarise(nat_avg = first(dealsize)) |>
  pull(nat_avg)

avg_data <- avg_data |>
  mutate(pct_of_nat = dealsize / nat_avg)

# -----------------------------
# 2) Plot
# -----------------------------

avg_data |>
  ggplot(aes(x = avg_label, y = dealsize, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "Midwest (excl. WI)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "National (excl. CA, MA, NY)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        TRUE ~ NA_character_
      )),
    position = position_dodge(width = 0.75),
    vjust = -0.6,
    size = 3,
    na.rm = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin" = "#c5050c",
      "Midwest (excl. WI)" = "blue",
      "National (excl. CA, MA, NY)" = "grey60",
      "National" = "black"
    )) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Venture Capital Deal Size: Wisconsin vs National Average",
    subtitle = "2015–2025 total",
    x        = NULL,
    y        = "USD (Millions)",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q4 2025. Percents above each bar refer to the percent of National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealsize

save_fig(
  p = vc_dealsize,
  filename = file.path(output_dir, "3_vc_dealsize.jpeg"),
  w = 16.5,
  h = 5.5
)
