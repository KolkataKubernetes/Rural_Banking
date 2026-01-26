#///////////////////////////////////////////////////////////////////////////////
#----                Figure 2: VC Capital Committed (WI vs US)            ----
# File name:  1_2_2_vc_dealvol_fig2.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot venture capital deal volume time series comparisons.
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

vol_ts_data <- readRDS(file.path("2_processed_data", "vol_ts_data.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

vol_ts_data |>
  select(year, dealvol_national, dealvol_wi, dealvol_national_nonoutlier, dealvol_midwest,
         wi_pct, nonoutlier_pct, midwest_pct) |>
  pivot_longer(
    cols = c(dealvol_national, dealvol_national_nonoutlier, dealvol_wi, dealvol_midwest),
    names_to = "series",
    values_to = "dealvol"
  ) |>
  mutate(
    series = recode(series,
                    dealvol_national = "National avg.",
                    dealvol_national_nonoutlier = "National avg. (excl. CA, MA, NY)",
                    dealvol_midwest = "Midwest avg. (excl. WI)",
                    dealvol_wi = "Wisconsin"
    )) |>
  mutate(
    series = factor(
      series,
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  ) |>
  ggplot(aes(x = factor(year), y = dealvol, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(wi_pct, accuracy = 1.0),
        series == "Midwest avg. (excl. WI)" ~ scales::percent(midwest_pct, accuracy = 1.0),
        series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(nonoutlier_pct, accuracy = 1.0),
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
      "Midwest avg. (excl. WI)" = "blue",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "National avg." = "black"
    )) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Venture Capital Capital Committed: Wisconsin vs National Average",
    subtitle = "2015–2024",
    x        = "Year",
    y        = "USD (Millions)",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q3 2025. Percents above each bar refer to the percent of National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealvol

save_fig(
  p = vc_dealvol,
  filename = file.path(output_dir, "2_vc_capcommitted.jpeg"),
  w = 16.5,
  h = 5.5
)
